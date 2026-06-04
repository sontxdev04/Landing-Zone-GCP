variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

# Service account that Terraform impersonates when applying this stack (created manually — see README §6.1).
variable "tf_runner_sa" {
  description = "Email of the TF Runner SA dedicated to the management stack"
  type        = string
}

# Destination email for Cloud Monitoring alerts and budget notifications.
variable "alert_notification_email" {
  description = "Email address that receives monitoring alerts and budget threshold notifications"
  type        = string
}

# Billing account whose spend is tracked by the monthly cost budget.
# Typically set to one of org.billing_account_id_1/_2 (or a separate dedicated one).
variable "budget_billing_account_id" {
  description = "Billing account ID that the monthly cost budget tracks spend for"
  type        = string
}
