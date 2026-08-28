variable "customer_id" {
  description = "Customer ID Workspace (gcloud organizations list -> DIRECTORY_CUSTOMER_ID)."
  type        = string
  default     = "C01uza5dm"
}

variable "domain" {
  description = "Domaine principal Workspace."
  type        = string
  default     = "au-tapas-ecossais.com"
}
