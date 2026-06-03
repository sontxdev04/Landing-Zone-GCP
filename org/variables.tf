variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID linked to every project created by the org stack"
  type        = string
}
