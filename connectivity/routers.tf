# =============================================================================
# CONNECTIVITY · Cloud Routers
# -----------------------------------------------------------------------------
# Mục đích : Router hub chạy phiên BGP cho VPN; router NAT phục vụ Cloud NAT.
# =============================================================================

# Cloud Router trong hub VPC (ASN 65003) cho phiên BGP của VPN
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
      description = "Dải subnet của Shared VPC prod"
    }
  }
}

# Cloud Router cho NAT trong Shared VPC prod
resource "google_compute_router" "gcp-sg-router-nat-001" {
  name    = "gcp-sg-router-nat-001"
  project = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  region  = "asia-southeast1"
  network = google_compute_network.gcp-sg-vpc-shared-001.id
}
