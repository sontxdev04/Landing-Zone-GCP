# Cloud Routers — shared routing plane for VPN (BGP) and NAT

# Cloud Router in hub VPC (ASN 65003) for VPN BGP sessions
resource "google_compute_router" "gcp-sg-router-hub-001" {
  name    = "gcp-sg-router-hub-001"
  project = data.google_project.gcp-sg-prj-hub-net-001.project_id
  region  = "asia-southeast1"
  network = google_compute_network.gcp-sg-vpc-hub-001.id

  bgp {
    asn               = 65003
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    advertised_ip_ranges {
      range       = "10.20.0.0/20"
      description = "shared-prod VPC subnets"
    }
  }
}

# Cloud Router for NAT in prod shared VPC
resource "google_compute_router" "gcp-sg-router-nat-001" {
  name    = "gcp-sg-router-nat-001"
  project = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  region  = "asia-southeast1"
  network = google_compute_network.gcp-sg-vpc-shared-001.id
}
