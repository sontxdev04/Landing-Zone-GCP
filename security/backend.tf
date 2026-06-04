# =============================================================================
# SECURITY · Backend GCS — lưu trữ Terraform state của stack security
# -----------------------------------------------------------------------------
# Mục đích : Cấu hình backend GCS để lưu state của stack security.
#            Mỗi stack dùng prefix riêng nhằm cô lập state (Separation of Duties).
# =============================================================================
terraform {
  backend "gcs" {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/security"
  }
}
