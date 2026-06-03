# Management stack outputs — add outputs here as you extend the stack

output "dashboard_infra_id" {
  description = "Resource ID of the Infrastructure Overview dashboard"
  value       = google_monitoring_dashboard.gcp-sg-dashboard-infra-001.id
}

output "dashboard_availability_id" {
  description = "Resource ID of the Availability dashboard"
  value       = google_monitoring_dashboard.gcp-sg-dashboard-availability-001.id
}

output "budget_id" {
  description = "Resource ID of the monthly cost budget (null when billing_account_id is empty)"
  value       = try(google_billing_budget.gcp-sg-budget-monthly-001[0].id, null)
}

