# =============================================================================
# SECURITY · Remote state — đọc output của stack org
# -----------------------------------------------------------------------------
# Mục đích : Nạp output từ state của stack org (project ID...). Apply org TRƯỚC.
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
