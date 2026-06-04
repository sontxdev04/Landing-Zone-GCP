# =============================================================================
# ORG · Backend GCS — lưu trữ Terraform state của stack org
# -----------------------------------------------------------------------------
# Mục đích : Cấu hình backend GCS để lưu state của stack org.
#            Mỗi stack dùng prefix riêng nhằm cô lập state (Separation of Duties).
# =============================================================================
terraform {
  backend "gcs" {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/org"
  }
}
