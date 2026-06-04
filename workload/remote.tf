# Remote state — reads org + connectivity stack outputs (apply org & connectivity first)

data "terraform_remote_state" "org" {
  backend = "gcs"
  config = {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/org"
  }
}

# Connectivity outputs — Shared VPC / subnet refs cho VM workload
data "terraform_remote_state" "connectivity" {
  backend = "gcs"
  config = {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/connectivity"
  }
}

# Convenience local aliases
locals {
  org  = data.terraform_remote_state.org.outputs
  conn = data.terraform_remote_state.connectivity.outputs
}
