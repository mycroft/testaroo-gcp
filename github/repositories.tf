module "testaroo_github" {
  source = "./modules/repository"

  name        = "testaroo-github"
  description = "Dépôt géré par Terraform depuis mycroft/testaroo-gcp (stack github/)."
  topics      = ["terraform", "testaroo"]

  # Les rulesets sur dépôt privé exigent GitHub Pro pour un compte perso.
  visibility = "public"

  required_approving_review_count = 0 # un seul humain sur ce compte
}
