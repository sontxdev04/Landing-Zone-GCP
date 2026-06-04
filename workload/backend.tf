# =============================================================================
# WORKLOAD · Backend GCS — lưu trữ Terraform state của stack workload
# -----------------------------------------------------------------------------
# Mục đích : Cấu hình backend GCS để lưu state của stack workload.
#            Mỗi stack dùng prefix riêng nhằm cô lập state (Separation of Duties).
# =============================================================================
terraform {
  backend "gcs" {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/workload"
  }
}
