# =============================================================================
# MANAGEMENT · Remote state — đọc output của org
# -----------------------------------------------------------------------------
# Mục đích : Nạp output từ state org (project ID, folder ID...) cho các tài
#            nguyên monitoring/logging. Apply org TRƯỚC.
# =============================================================================

data "terraform_remote_state" "org" {
  backend = "gcs"
  config = {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/org"
  }
}

# Bí danh local cho tiện tham chiếu
locals {
  org = data.terraform_remote_state.org.outputs
}
