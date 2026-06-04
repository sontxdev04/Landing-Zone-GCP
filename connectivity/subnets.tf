# Subnets

# Hub subnet (10.0.0.0/24) — hub-net project, VPN/Router termination
resource "google_compute_subnetwork" "gcp-sg-snet-hub-001" {
  name                     = "gcp-sg-snet-hub-001"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = "asia-southeast1"
  network                  = google_compute_network.gcp-sg-vpc-hub-001.id
  project                  = data.google_project.gcp-sg-prj-hub-net-001.project_id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# App subnet (10.20.1.0/24) — prod shared VPC workloads
resource "google_compute_subnetwork" "gcp-sg-snet-app-001" {
  name                     = "gcp-sg-snet-app-001"
  ip_cidr_range            = "10.20.1.0/24"
  region                   = "asia-southeast1"
  network                  = google_compute_network.gcp-sg-vpc-shared-001.id
  project                  = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.1
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
