# Remote state — reads connectivity and org stack outputs (apply both first)

data "terraform_remote_state" "connectivity" {
  backend = "gcs"
  config = {
    bucket = "gcp-sg-tf-state-54431047904-001"
    prefix = "terraform/connectivity"
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
  conn = data.terraform_remote_state.connectivity.outputs
  org  = data.terraform_remote_state.org.outputs
}
