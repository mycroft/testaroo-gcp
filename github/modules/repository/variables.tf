variable "name" {
  description = "Nom du dépôt."
  type        = string
}

variable "description" {
  description = "Description du dépôt."
  type        = string
  default     = ""
}

variable "visibility" {
  description = "public ou private. Les rulesets sur dépôt privé exigent GitHub Pro/Team."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.visibility)
    error_message = "visibility doit valoir public ou private."
  }
}

variable "topics" {
  description = "Topics GitHub."
  type        = list(string)
  default     = []
}

variable "default_branch" {
  description = "Branche par défaut, créée et protégée."
  type        = string
  default     = "main"
}

variable "has_issues" {
  type    = bool
  default = true
}

variable "allow_auto_merge" {
  type    = bool
  default = false
}

variable "required_linear_history" {
  description = "Exiger un historique linéaire (false pour les monorepos, comme tf-it)."
  type        = bool
  default     = true
}

variable "required_approving_review_count" {
  description = "Nombre d'approbations requises sur la branche par défaut."
  type        = number
  default     = 1
}

variable "status_check_contexts" {
  description = "Checks CI obligatoires avant merge (noms de jobs)."
  type        = list(string)
  default     = []
}

variable "admins_can_bypass" {
  description = "Autoriser les admins du dépôt à contourner le ruleset."
  type        = bool
  default     = true
}
