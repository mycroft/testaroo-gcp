output "bucket_name" {
  description = "Bucket à référencer dans les blocs backend \"gcs\" des autres stacks."
  value       = google_storage_bucket.tfstate.name
}

output "backend_snippet" {
  description = "Bloc backend à copier dans une autre stack (remplacer <stack>)."
  value       = <<-EOT
    backend "gcs" {
      bucket = "${google_storage_bucket.tfstate.name}"
      prefix = "<stack>"
    }
  EOT
}
