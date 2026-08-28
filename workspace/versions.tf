terraform {
  required_version = ">= 1.6"

  required_providers {
    googleworkspace = {
      source  = "hashicorp/googleworkspace"
      version = "~> 0.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "gcs" {
    bucket = "mkz-me-tfstate"
    prefix = "workspace"
  }
}

# Auth : ADC. En CI, WIF -> impersonation de github-workspace@ ; en local, tes
# ADC (`gcloud auth application-default login` avec un compte admin du domaine).
# Le SA agit en son nom propre : il doit porter un rôle admin Workspace
# (Groups Admin + User Management Admin) dans admin.google.com. Pas de domain-wide delegation ici.
provider "googleworkspace" {
  customer_id = var.customer_id
  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.group",
    "https://www.googleapis.com/auth/admin.directory.group.member",
    "https://www.googleapis.com/auth/apps.groups.settings",
  ]
}
