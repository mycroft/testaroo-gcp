variable "project_id" {
  description = "Projet GCP hébergeant le bucket de state."
  type        = string
  default     = "mkz-me"
}

variable "region" {
  description = "Région par défaut du provider."
  type        = string
  default     = "europe-west1"
}

variable "bucket_name" {
  description = "Nom (globalement unique) du bucket de state Terraform."
  type        = string
  default     = "mkz-me-tfstate"
}

variable "location" {
  description = "Location du bucket (région ou multi-région)."
  type        = string
  default     = "EU"
}
