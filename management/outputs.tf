# =============================================================================
# MANAGEMENT · Outputs
# -----------------------------------------------------------------------------
# Mục đích : Xuất ID các dashboard monitoring và ngân sách tháng.
# =============================================================================

output "dashboard_infra_id" {
  description = "Resource ID của dashboard Infrastructure Overview"
  value       = google_monitoring_dashboard.gcp-sg-dashboard-infra-001.id
}

output "dashboard_availability_id" {
  description = "Resource ID của dashboard Availability"
  value       = google_monitoring_dashboard.gcp-sg-dashboard-availability-001.id
}

output "budget_id" {
  description = "Resource ID của ngân sách tháng (null khi budget_billing_account_id rỗng)"
  value       = try(google_billing_budget.gcp-sg-budget-monthly-001[0].id, null)
}
