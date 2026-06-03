# Shared VPC — prod host project + service project attachment

# Enable Shared VPC host on prod shared VPC project
resource "google_compute_shared_vpc_host_project" "gcp-sg-shared-vpc-host-001" {
  project = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
}

# Attach prd-env as service project to prod shared VPC host
resource "google_compute_shared_vpc_service_project" "gcp-sg-shared-vpc-service-001" {
  host_project    = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  service_project = data.google_project.gcp-sg-prj-astronomy-shop-001.project_id
  depends_on      = [google_compute_shared_vpc_host_project.gcp-sg-shared-vpc-host-001]
}
