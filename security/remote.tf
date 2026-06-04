# Remote state — reads org stack outputs (apply org first)

data "terraform_remote_state" "org" {
  backend = "gcs"
  config = {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/org"
  }
}

# Convenience local aliases
locals {
  org = data.terraform_remote_state.org.outputs
}
