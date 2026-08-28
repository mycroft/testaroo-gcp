# TODO

Dette assumée pendant le POC, à reprendre.

## Identité et org policies

- [ ] Donner `roles/owner` sur `mkz-me` à `admin@au-tapas-ecossais.com` (possible sans invitation maintenant que le projet est dans l'org), puis retirer `codingmyc@gmail.com` de la policy du projet.
- [ ] Réactiver `iam.allowedPolicyMemberDomains` sur l'org (`allowedValues: [C01uza5dm]`) une fois le gmail sorti — désactivée le 2026-08-28 pour permettre le move du projet.
- [ ] Retirer les bindings temporaires du move : `roles/resourcemanager.projectMover` (gmail + admin@) et `roles/resourcemanager.projectIamAdmin` (admin@) sur `mkz-me`.

## IAM du state

- [ ] Remplacer `roles/storage.objectAdmin` par un rôle custom minimal `tf_state_manager` (`storage.buckets.get`, `storage.objects.{get,list,create,delete}`) comme `tf-it/gworkspace/state.tf`.
- [ ] Binder ce rôle à un groupe Workspace plutôt qu'à des utilisateurs, pour fermer la boucle Workspace → IAM GCP (pattern `role-*@vibe.co`).

## GitHub

- [ ] `GH_TF_TOKEN` est le seul secret long-lived : noter son expiration et prévoir le renouvellement ; passer à une GitHub App si le dépôt migre vers une organisation.
- [ ] Réduire `project_roles` de `github-terraform` (`oidc/variables.tf`) ; envisager un SA plan (lecture) / SA apply (écriture) via `attribute.ref`.

## CI

- [ ] Ne planifier que les stacks modifiées (terramate change detection) au lieu de quatre plans à chaque push.
