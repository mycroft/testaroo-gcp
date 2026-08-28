# testaroo-gcp

Bac à sable Terraform sur le projet GCP `mkz-me`, avec plan automatique sur PR et apply automatique sur `main`.

## Layout

- `backend/` — bucket GCS `mkz-me-tfstate` qui héberge le state de toutes les stacks (versioning + rétention 20 versions, accès public interdit, `prevent_destroy`).
- `oidc/` — Workload Identity Federation : pool + provider OIDC GitHub restreint au dépôt, service account `github-terraform` impersonable par le repo, rôles projet et accès au bucket de state.
- `workspace/` — groupes Google Workspace du domaine `au-tapas-ecossais.com` via le provider `googleworkspace`, module `modules/group` calqué sur `tf-it`. Impersonne le SA dédié `github-workspace` (aucun rôle GCP, rôle Groups Admin côté Workspace).
- `github/` — dépôts GitHub du compte `mycroft` via le provider `integrations/github`, module `modules/repository` calqué sur `tf-it/modules/github_private_repository` (squash/rebase, branche par défaut, ruleset : pas de suppression ni force-push, PR obligatoire, checks optionnels). Gère `mycroft/testaroo-github`. State via `github-terraform`.
- `.github/workflows/terraform.yml` — un job par stack, chaîné par `needs` (`backend` → `oidc` → `workspace`) pour que les APIs/IAM posés par `oidc/` existent avant les stacks qui en dépendent. Chaque job appelle le workflow réutilisable `tf-stack.yml` : `fmt`/`init`/`validate`/`plan` sur PR (plan posté en commentaire), `apply` sur push `main`, échec explicite si un secret manque, un SA par stack (`sa_secret`), auth par Workload Identity Federation (aucune clé JSON dans GitHub).

## Bootstrap (une seule fois, en local)

Le bucket ne peut pas stocker son propre state avant d'exister : premier apply en state local, puis migration.

`gcloud auth` ne fixe pas de projet : l'auth c'est l'identité, le projet se règle à part. Terraform utilise les ADC (Application Default Credentials) et le `project_id` de la config (`mkz-me` par défaut dans `variables.tf`), pas `gcloud config`.

```sh
gcloud auth login                                          # compte perso, pour la CLI gcloud
gcloud auth application-default login                      # ADC, utilisés par Terraform
gcloud config set project mkz-me                           # projet par défaut de gcloud
gcloud auth application-default set-quota-project mkz-me   # projet de quota des ADC
gcloud config list && gcloud auth list                     # vérification
```

Pour ne pas mélanger avec un compte pro, utiliser une configuration nommée :

```sh
gcloud config configurations create perso
gcloud config set account <email-perso>
gcloud config set project mkz-me
gcloud config configurations activate perso   # ou `default` pour revenir
```

```sh
cd backend
terraform init
terraform apply
# décommenter le bloc backend "gcs" dans versions.tf, puis :
terraform init -migrate-state
rm -f terraform.tfstate terraform.tfstate.backup
```

## Auth GitHub Actions (Workload Identity Federation)

Pas de clé de service account dans GitHub : le runner échange son token OIDC GitHub contre un token GCP en impersonnant `github-terraform@mkz-me.iam.gserviceaccount.com`. Tout est dans `oidc/` ; le premier apply se fait en local avec tes ADC (le SA n'existe pas encore pour que CI le fasse).

```sh
cd oidc
terraform init
terraform apply
terraform output -raw gh_secrets_commands | sh   # crée les 2 secrets GitHub
```

Secrets créés : `GCP_WORKLOAD_IDENTITY_PROVIDER` et `GCP_SERVICE_ACCOUNT`. Ensuite CI se suffit à elle-même, y compris pour modifier `oidc/`.

La première exécution CI juste après l'apply peut échouer avec `Permission 'iam.serviceAccounts.getAccessToken' denied` : c'est la propagation IAM (quelques minutes) sur le SA et le pool fraîchement créés, pas une erreur de config. Relancer le job. Si ça persiste, vérifier que les secrets correspondent aux outputs (`terraform output`) — l'action `auth` n'échange pas le token, la première erreur remonte donc au premier appel Terraform.

Garde-fous : `attribute_condition` limite le provider à `mycroft/testaroo-gcp` ; le binding `workloadIdentityUser` est aussi scopé à ce dépôt. Les rôles projet (`oidc/variables.tf`, `project_roles`) sont larges parce que le SA gère l'IAM lui-même — à réduire ou à splitter en SA plan (lecture) / SA apply (écriture) quand tu voudras aller plus loin.

## Google Workspace

Prérequis manuels (une fois) :

1. Cloud Identity Free souscrit et domaine vérifié ; l'Organisation GCP apparaît au premier login console avec un compte du domaine (`gcloud organizations list`).
2. `oidc/` appliqué (crée `github-workspace@mkz-me.iam.gserviceaccount.com` et active `admin.googleapis.com`).
3. Dans `admin.google.com` → Compte → Rôles admin → **Groups Admin** et **User Management Admin** → Attribuer un service account : coller `terraform -chdir=oidc output -raw workspace_service_account_email`. Sans domain-wide delegation : le SA agit en son nom.
4. `gh secret set GCP_WORKSPACE_SERVICE_ACCOUNT --repo mycroft/testaroo-gcp --body "$(terraform -chdir=oidc output -raw workspace_service_account_email)"`

Utilisateurs (`users.tf`) et groupes/membres (`groups.tf`) sont déclarés dans des `locals` ; les mots de passe initiaux sont générés (`random_password`), stockés dans le state GCS et ignorés ensuite. Pour les OU, ajouter le scope `admin.directory.orgunit`.

### Rattacher `mkz-me` à l'organisation (fait le 2026-08-28)

Le projet a été créé hors org par un compte `@gmail.com`. Pièges rencontrés :

- `SOLO_MUST_INVITE_OWNERS` : hors org, un nouveau owner doit être invité via la console. Contourné en donnant `roles/resourcemanager.projectMover` **et** `roles/resourcemanager.projectIamAdmin` au compte admin du domaine — le move (`UpdateProject` avec nouveau parent) exige `projects.update` et `projects.setIamPolicy`, visible dans l'audit log du projet.
- `organizationAdmin` n'inclut ni `projects.create` ni la gestion des org policies : ajouter `roles/resourcemanager.projectCreator` et `roles/orgpolicy.policyAdmin` sur l'org.
- Org policies par défaut d'une nouvelle org : `iam.allowedPolicyMemberDomains` (reset, à remettre une fois le gmail retiré du projet) et `resourcemanager.allowedImportSources` (ouverte avec `allowAll` le temps du move, puis supprimée).

Diagnostic qui a tranché : `gcloud logging read 'protoPayload.methodName="UpdateProject"' --project mkz-me --format=json` → `authorizationInfo[].granted`.

## GitHub

Le provider `github` s'authentifie par `GITHUB_TOKEN`. Le `GITHUB_TOKEN` automatique d'Actions ne peut pas créer de dépôts : il faut un **fine-grained PAT** (Settings → Developer settings → Personal access tokens → Fine-grained), périmètre minimal :

- Resource owner : `mycroft` ; Repository access : *All repositories* (nécessaire pour en créer) ;
- Permissions : Administration (read/write), Contents (read/write), Metadata (read).
- Expiration courte (90 j max) ; noter la date et la renouveler — c'est le seul secret long-lived du dépôt, GitHub n'offrant pas d'OIDC vers sa propre API pour un compte perso. Sur une organisation, préférer une GitHub App.

```sh
gh secret set GH_TF_TOKEN --repo mycroft/testaroo-gcp   # coller le PAT
```

En local : `set -x GITHUB_TOKEN (gh auth token)` suffit (le token `gh` a les scopes `repo`), avec les ADC/impersonation `github-terraform` pour le state.

Limites d'un compte perso par rapport à tf-it : pas d'équipes (`github_team*`), donc pas de `github_team_repository` ; les rulesets sur dépôt **privé** exigent GitHub Pro — `testaroo-github` est donc public.

## Ajouter une stack

1. Créer `<stack>/` avec un bloc `backend "gcs" { bucket = "mkz-me-tfstate" prefix = "<stack>" }` (cf. output `backend_snippet`).
2. Ajouter un job dans `terraform.yml` appelant `tf-stack.yml`, avec `needs: oidc` et le `sa_secret` adapté.
