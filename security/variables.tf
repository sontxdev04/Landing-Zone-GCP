variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

# Service account that Terraform impersonates when applying this stack (created manually — see README §6.1).
variable "tf_runner_sa" {
  description = "Email of the TF Runner SA dedicated to the security stack"
  type        = string
}

# Accepts any IAM principal with full prefix, e.g. "group:grp-sre@company.com" or "user:alice@company.com".
variable "admin_principals" {
  description = "IAM principals (groups preferred) that receive org-level admin roles"
  type        = list(string)
}
