terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "mkz-me-tfstate"
    prefix = "oidc"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
