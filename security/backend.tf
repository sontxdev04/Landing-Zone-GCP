terraform {
  backend "gcs" {
    bucket = "gcp-sg-tf-state-54431047904-001"
    prefix = "terraform/security"
  }
}
