data "google_project" "this" {
  project_id = var.project_id
}

resource "google_project_service" "apis" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# --- Workload Identity Federation -------------------------------------------

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
  description               = "Identités OIDC des runners GitHub Actions."

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Claims du token GitHub -> attributs GCP.
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }

  # Seul ce dépôt peut obtenir un token via ce provider.
  attribute_condition = "assertion.repository == \"${var.github_repository}\""
}

# --- Service account utilisé par le workflow --------------------------------

resource "google_service_account" "github" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "GitHub Actions Terraform"
  description  = "Impersonné par ${var.github_repository} via WIF pour terraform plan/apply."
}

# Autorise les tokens du dépôt à impersonner le SA.
resource "google_service_account_iam_member" "wif" {
  service_account_id = google_service_account.github.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

resource "google_project_iam_member" "github" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = google_service_account.github.member
}

# Lecture/écriture du state.
resource "google_storage_bucket_iam_member" "state" {
  bucket = var.state_bucket
  role   = "roles/storage.objectAdmin"
  member = google_service_account.github.member
}
