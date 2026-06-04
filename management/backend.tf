# =============================================================================
# MANAGEMENT · Backend GCS — lưu trữ Terraform state của stack management
# -----------------------------------------------------------------------------
# Mục đích : Cấu hình backend GCS để lưu state của stack management.
#            Mỗi stack dùng prefix riêng nhằm cô lập state (Separation of Duties).
# =============================================================================
terraform {
  backend "gcs" {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/management"
  }
}
