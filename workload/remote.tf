# Remote state — reads org stack outputs (apply org stack first)
# NOTE: connectivity remote state removed — bastion host (which needed conn outputs) has been replaced by Cloud IAP.
# Re-add connectivity remote state here when workload VMs need subnet/VPC references.

data "terraform_remote_state" "org" {
  backend = "gcs"
  config = {
    bucket = "gcp-sg-tf-state-54431047904-001"
    prefix = "terraform/org"
  }
}

# Convenience local aliases
locals {
  org = data.terraform_remote_state.org.outputs
}
