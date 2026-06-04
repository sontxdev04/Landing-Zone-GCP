# VPC Peering — Hub ↔ Prod (Shared VPC)
# NOTE: sh-access VPC removed along with bastion host. Access is via Cloud IAP.

resource "google_compute_network_peering" "gcp-sg-peering-hub-to-app-001" {
  name                 = "gcp-sg-peering-hub-to-app-001"
  network              = google_compute_network.gcp-sg-vpc-hub-001.self_link
  peer_network         = google_compute_network.gcp-sg-vpc-shared-001.self_link
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_network_peering" "gcp-sg-peering-app-to-hub-001" {
  name                 = "gcp-sg-peering-app-to-hub-001"
  network              = google_compute_network.gcp-sg-vpc-shared-001.self_link
  peer_network         = google_compute_network.gcp-sg-vpc-hub-001.self_link
  export_custom_routes = true
  import_custom_routes = true
  depends_on           = [google_compute_network_peering.gcp-sg-peering-hub-to-app-001]
}
