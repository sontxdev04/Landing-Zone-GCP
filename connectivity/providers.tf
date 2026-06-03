terraform {
  required_version = "1.14.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }
  }
}

provider "google" {
  region                = "asia-southeast1"
  user_project_override = true
  billing_project       = local.org.project_id_hub_net
}
