# VPC Peering — hub-spoke topology (non-transitive, full-mesh workaround)

# Hub <-> Prod (app)
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
}

# Access <-> Prod (Bastion SSH)
resource "google_compute_network_peering" "gcp-sg-peering-access-to-app-001" {
  name                 = "gcp-sg-peering-access-to-app-001"
  network              = google_compute_network.gcp-sg-vpc-shared-access-001.self_link
  peer_network         = google_compute_network.gcp-sg-vpc-shared-001.self_link
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_network_peering" "gcp-sg-peering-app-to-access-001" {
  name                 = "gcp-sg-peering-app-to-access-001"
  network              = google_compute_network.gcp-sg-vpc-shared-001.self_link
  peer_network         = google_compute_network.gcp-sg-vpc-shared-access-001.self_link
  export_custom_routes = true
  import_custom_routes = true
}
