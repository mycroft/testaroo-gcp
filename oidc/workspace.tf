# Service account dédié à Google Workspace / Cloud Identity.
#
# Séparé de github-terraform : celui-ci ne porte AUCUN rôle GCP. Ses droits
# viennent de l'Admin console Workspace (rôle admin ou domain-wide delegation),
# qui n'accepte qu'un service account — pas un principal WIF.
#
# À faire à la main après l'apply, dans admin.google.com :
#   - Compte > Rôles admin > attribuer un rôle (Groups Admin, ou rôle custom
#     Users/Groups/OU) à l'email du SA ; ou
#   - Sécurité > Contrôle des API > Délégation au niveau du domaine : ajouter
#     le client ID du SA (output workspace_sa_unique_id) avec les scopes
#     admin.directory.{group,group.member,user,orgunit}.

resource "google_project_service" "workspace_apis" {
  for_each = toset([
    "admin.googleapis.com",
    "cloudidentity.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "workspace" {
  project      = var.project_id
  account_id   = var.workspace_service_account_id
  display_name = "GitHub Actions Workspace"
  description  = "Impersonné par ${var.github_repository} via WIF pour gérer l'annuaire Workspace."
}

resource "google_service_account_iam_member" "workspace_wif" {
  service_account_id = google_service_account.workspace.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

# Lecture/écriture du state de la stack workspace/.
resource "google_storage_bucket_iam_member" "workspace_state" {
  bucket = var.state_bucket
  role   = "roles/storage.objectAdmin"
  member = google_service_account.workspace.member
}
