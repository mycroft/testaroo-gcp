resource "google_project_service" "storage" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "tfstate" {
  name          = var.bucket_name
  project       = var.project_id
  location      = var.location
  storage_class = "STANDARD"

  # Interdit la suppression du bucket tant qu'il contient des objets.
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Historique des states : indispensable pour revenir en arrière.
  versioning {
    enabled = true
  }

  # Ne garde que les 20 dernières versions non courantes de chaque state.
  lifecycle_rule {
    condition {
      num_newer_versions = 20
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.storage]
}
