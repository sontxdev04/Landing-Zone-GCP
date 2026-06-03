variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "user_email" {
  description = "Personal GCP account email - used for org-level IAM bindings"
  type        = string
}
