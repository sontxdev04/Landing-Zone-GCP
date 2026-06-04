terraform {
  required_version = "1.14.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.50.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
  }
}

provider "google" {
  impersonate_service_account = var.tf_runner_sa
  region                      = "asia-southeast1"
}

provider "google-beta" {
  impersonate_service_account = var.tf_runner_sa
  region                      = "asia-southeast1"
}
