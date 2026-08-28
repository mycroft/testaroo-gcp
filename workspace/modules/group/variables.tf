variable "emails" {
  description = "Adresses des groupes à créer."
  type        = list(string)
}

variable "allow_external_members" {
  description = "Autoriser des membres hors domaine."
  type        = bool
  default     = false
}

variable "who_can_post_message" {
  description = "Qui peut poster (ANYONE_CAN_POST, ALL_IN_DOMAIN_CAN_POST, ALL_MEMBERS_CAN_POST, ...)."
  type        = string
  default     = "ALL_MEMBERS_CAN_POST"
}
