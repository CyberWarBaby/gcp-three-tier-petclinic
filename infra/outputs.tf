output "service_acc_details" {
  value = google_service_account.app_sa.email
}
output "web_service_acc_details" {
  value = google_service_account.web_sa.email
}