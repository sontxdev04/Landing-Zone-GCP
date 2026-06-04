# =============================================================================
# WORKLOAD · Remote state — đọc output của org + connectivity
# -----------------------------------------------------------------------------
# Mục đích : Nạp output từ state org (project ID) và connectivity (Shared VPC,
#            subnet) để gắn VM. Apply org & connectivity TRƯỚC.
# =============================================================================

data "terraform_remote_state" "org" {
  backend = "gcs"
  config = {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/org"
  }
}

# Output connectivity — tham chiếu Shared VPC / subnet cho VM workload
data "terraform_remote_state" "connectivity" {
  backend = "gcs"
  config = {
    bucket = "<STATE_BUCKET>"
    prefix = "terraform/connectivity"
  }
}

# Bí danh local cho tiện tham chiếu
locals {
  org  = data.terraform_remote_state.org.outputs
  conn = data.terraform_remote_state.connectivity.outputs
}
