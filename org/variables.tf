variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

# Service account that Terraform impersonates when applying this stack (created manually — see README §6.1).
variable "tf_runner_sa" {
  description = "Email of the TF Runner SA dedicated to the org stack"
  type        = string
}

variable "billing_account_id_1" {
  description = "Billing account ID 1 used for platform management and security projects"
  type        = string
}

variable "billing_account_id_2" {
  description = "Billing account ID 2 used for networking and workload projects"
  type        = string
}

# The zone B of Singapore region (used by the bastion VM org policy exception).
variable "zone_sg_b" {
  description = "The zone B of Singapore region"
  type        = string
  default     = "asia-southeast1-b"
}
