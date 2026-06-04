# Service account that Terraform impersonates when applying this stack (created manually — see README §6.1).
variable "tf_runner_sa" {
  description = "Email of the TF Runner SA dedicated to the workload stack"
  type        = string
}

# The zone B of Singapore region (where the bastion VM lives).
variable "zone_sg_b" {
  description = "The zone B of Singapore region"
  type        = string
  default     = "asia-southeast1-b"
}

# Machine type of the bastion VM.
variable "bastion_machine_type" {
  description = "Machine type of the bastion VM"
  type        = string
  default     = "e2-micro"
}

# Boot image of the bastion VM.
variable "bastion_image" {
  description = "Boot image of the bastion VM"
  type        = string
  default     = "debian-cloud/debian-12"
}
