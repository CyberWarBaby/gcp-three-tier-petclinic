output "project_id" {
  value = var.project
}

output "wif_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "ci_sa_email" {
  value = google_service_account.ci.email
}
