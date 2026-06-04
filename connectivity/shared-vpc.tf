# =============================================================================
# CONNECTIVITY · Shared VPC — host project + gắn service project
# -----------------------------------------------------------------------------
# Mục đích : Bật chế độ Host cho project sh-vpc và gắn sample-app làm
#            service project — tách quyền mạng khỏi quyền ứng dụng (SoD).
# =============================================================================

# Bật Shared VPC host trên project Shared VPC prod
resource "google_compute_shared_vpc_host_project" "gcp-sg-shared-vpc-host-001" {
  project = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
}

# Gắn sample-app làm service project vào Shared VPC host
resource "google_compute_shared_vpc_service_project" "gcp-sg-shared-vpc-service-001" {
  host_project    = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  service_project = data.google_project.gcp-sg-prj-sample-app-001.project_id
  depends_on      = [google_compute_shared_vpc_host_project.gcp-sg-shared-vpc-host-001]
}
