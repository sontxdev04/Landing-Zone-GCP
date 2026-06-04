# =============================================================================
# SECURITY · Providers & ràng buộc phiên bản
# -----------------------------------------------------------------------------
# Mục đích : Khóa phiên bản Terraform/provider, cấu hình impersonation và
#            user_project_override định tuyến billing/quota về project management.
# Phụ thuộc: var.tf_runner_sa, local.org.project_id_management.
# =============================================================================
terraform {
  required_version = "1.14.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }
  }
}

# Mạo danh SA runner của stack security.
provider "google" {
  impersonate_service_account = var.tf_runner_sa
  region                      = "asia-southeast1"
  user_project_override       = true
  billing_project             = local.org.project_id_management
}
