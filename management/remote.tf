# Remote state — reads workload and org stack outputs (apply workload first)

data "terraform_remote_state" "workload" {
  backend = "gcs"
  config = {
    bucket = "gcp-sg-tf-state-54431047904-001"
    prefix = "terraform/workload"
  }
}

data "terraform_remote_state" "org" {
  backend = "gcs"
  config = {
    bucket = "gcp-sg-tf-state-54431047904-001"
    prefix = "terraform/org"
  }
}

# Convenience local aliases
locals {
  wl  = data.terraform_remote_state.workload.outputs
  org = data.terraform_remote_state.org.outputs
}
