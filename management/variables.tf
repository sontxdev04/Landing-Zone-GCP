variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "user_email" {
  description = "Personal GCP account email - used for monitoring notification channels"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID used to scope the cost budget (owned by Foundation/org team)"
  type        = string
}
