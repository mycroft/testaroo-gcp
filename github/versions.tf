terraform {
  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }

  backend "gcs" {
    bucket = "mkz-me-tfstate"
    prefix = "github"
  }
}

# Auth : variable d'environnement GITHUB_TOKEN (fine-grained PAT, cf. README).
# GitHub n'a pas d'équivalent WIF côté API pour un compte perso : le token reste
# un secret GitHub Actions, à durée de vie courte et à périmètre minimal.
provider "github" {
  owner = var.owner
}
