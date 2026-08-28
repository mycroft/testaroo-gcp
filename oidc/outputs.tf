output "workload_identity_provider" {
  description = "Valeur du secret GitHub GCP_WORKLOAD_IDENTITY_PROVIDER."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "service_account_email" {
  description = "Valeur du secret GitHub GCP_SERVICE_ACCOUNT."
  value       = google_service_account.github.email
}

output "gh_secrets_commands" {
  description = "Commandes gh pour renseigner les secrets du dépôt."
  value       = <<-EOT
    gh secret set GCP_WORKLOAD_IDENTITY_PROVIDER --repo ${var.github_repository} --body "${google_iam_workload_identity_pool_provider.github.name}"
    gh secret set GCP_SERVICE_ACCOUNT --repo ${var.github_repository} --body "${google_service_account.github.email}"
  EOT
}
