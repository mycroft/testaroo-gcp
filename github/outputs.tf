output "repositories" {
  description = "Dépôts gérés : URL et branche par défaut."
  value = {
    testaroo_github = module.testaroo_github.repository
  }
}
