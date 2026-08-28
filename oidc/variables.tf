variable "project_id" {
  description = "Projet GCP cible."
  type        = string
  default     = "mkz-me"
}

variable "region" {
  description = "Région par défaut du provider."
  type        = string
  default     = "europe-west1"
}

variable "github_repository" {
  description = "Dépôt GitHub autorisé, au format owner/name."
  type        = string
  default     = "mycroft/testaroo-gcp"
}

variable "state_bucket" {
  description = "Bucket GCS du state Terraform (créé par la stack backend/)."
  type        = string
  default     = "mkz-me-tfstate"
}

variable "pool_id" {
  description = "ID du Workload Identity Pool."
  type        = string
  default     = "github"
}

variable "service_account_id" {
  description = "ID (partie locale de l'email) du service account utilisé par GitHub Actions."
  type        = string
  default     = "github-terraform"
}

variable "project_roles" {
  description = "Rôles projet accordés au service account. Larges car il gère backend/ et oidc/ lui-même ; à réduire si les stacks se spécialisent."
  type        = list(string)
  default = [
    "roles/storage.admin",                   # bucket de state (backend/)
    "roles/serviceusage.serviceUsageAdmin",  # google_project_service
    "roles/iam.workloadIdentityPoolAdmin",   # pool + provider (oidc/)
    "roles/iam.serviceAccountAdmin",         # le SA lui-même (oidc/)
    "roles/resourcemanager.projectIamAdmin", # bindings projet (oidc/)
  ]
}
