# Output — consumed by the workload stack (bastion VM service account)
output "sa_sh_access_email" {
  description = "Email of the shared-access service account"
  value       = google_service_account.sa-sh-access.email
}
