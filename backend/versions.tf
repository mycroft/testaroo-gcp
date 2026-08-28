terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Bootstrap: le premier apply se fait en state local (bloc commenté).
  # Ensuite, décommenter et lancer `terraform init -migrate-state`.
  # backend "gcs" {
  #   bucket = "mkz-me-tfstate"
  #   prefix = "backend"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
