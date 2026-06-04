# =============================================================================
# CONNECTIVITY · VPC Networks
# -----------------------------------------------------------------------------
# Mục đích : Tạo Hub VPC (transit/VPN) và Shared VPC (workload). Cả hai dùng
#            routing_mode GLOBAL để sẵn sàng mở rộng đa region.
# =============================================================================

# Data source — tham chiếu tới các project
data "google_project" "gcp-sg-prj-hub-net-001" {
  project_id = local.org.project_id_hub_net
}

data "google_project" "gcp-sg-prj-sh-vpc-001" {
  project_id = local.org.project_id_sh_vpc
}

data "google_project" "gcp-sg-prj-sample-app-001" {
  project_id = local.org.project_id_sample_app
}

# Hub VPC — trung tâm transit / điểm chấm dứt VPN
resource "google_compute_network" "gcp-sg-vpc-hub-001" {
  name                    = "gcp-sg-vpc-hub-001"
  project                 = data.google_project.gcp-sg-prj-hub-net-001.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

# Shared VPC — chứa workload prod
resource "google_compute_network" "gcp-sg-vpc-shared-001" {
  name                    = "gcp-sg-vpc-shared-001"
  project                 = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}