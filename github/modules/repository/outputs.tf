output "repository" {
  description = "Attributs utiles du dépôt."
  value = {
    name           = github_repository.this.name
    full_name      = github_repository.this.full_name
    html_url       = github_repository.this.html_url
    ssh_clone_url  = github_repository.this.ssh_clone_url
    default_branch = github_branch_default.this.branch
  }
}
