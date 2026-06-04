# =============================================================================
# CONNECTIVITY · Outputs — dữ liệu liên-stack
# -----------------------------------------------------------------------------
# Mục đích : Xuất self_link của Shared VPC/subnet để stack workload gắn VM.
# =============================================================================

output "vpc_shared_self_link" {
  description = "Self link của Shared VPC network (host project sh-vpc)"
  value       = google_compute_network.gcp-sg-vpc-shared-001.self_link
}

output "snet_app_self_link" {
  description = "Self link của app subnet (10.20.1.0/24) trong Shared VPC"
  value       = google_compute_subnetwork.gcp-sg-snet-app-001.self_link
}

output "project_id_sh_vpc" {
  description = "Project ID của Shared VPC host"
  value       = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
}
