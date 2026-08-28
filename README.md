# testaroo-gcp

Bac à sable Terraform sur le projet GCP `mkz-me`, avec plan automatique sur PR et apply automatique sur `main`.

## Layout

- `backend/` — bucket GCS `mkz-me-tfstate` qui héberge le state de toutes les stacks (versioning + rétention 20 versions, accès public interdit, `prevent_destroy`).
- `.github/workflows/terraform.yml` — `fmt`/`init`/`validate`/`plan` sur PR (plan posté en commentaire), `apply` sur push `main`. Ajouter une stack = ajouter son dossier dans `matrix.stack`.

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

Pas de clé de service account dans GitHub. À créer une fois dans `mkz-me` (à terraformer ensuite dans une stack `iam/`) :

1. Un service account `github-terraform@mkz-me.iam.gserviceaccount.com` avec `roles/storage.admin` (limiter au bucket plus tard) et `roles/serviceusage.serviceUsageAdmin`.
2. Un Workload Identity Pool + provider OIDC GitHub (`https://token.actions.githubusercontent.com`), condition `assertion.repository == "mycroft/testaroo-gcp"`.
3. Binding `roles/iam.workloadIdentityUser` du SA vers `principalSet://.../attribute.repository/mycroft/testaroo-gcp`.

Secrets GitHub à renseigner :

- `GCP_WORKLOAD_IDENTITY_PROVIDER` — `projects/<project-number>/locations/global/workloadIdentityPools/<pool>/providers/<provider>`
- `GCP_SERVICE_ACCOUNT` — email du service account ci-dessus

## Ajouter une stack

1. Créer `<stack>/` avec un bloc `backend "gcs" { bucket = "mkz-me-tfstate" prefix = "<stack>" }` (cf. output `backend_snippet`).
2. L'ajouter à `matrix.stack` et aux `paths` du workflow.
