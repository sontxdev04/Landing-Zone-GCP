# Remote state — reads org stack outputs (apply org stack first)

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
