# Cloud DNS — private zone for internal name resolution across the landing zone

resource "google_dns_managed_zone" "gcp-sg-dns-internal-001" {
  name        = "gcp-sg-dns-internal-001"
  project     = data.google_project.gcp-sg-prj-hub-net-001.project_id
  dns_name    = "internal.lz.local."
  description = "Private DNS zone for internal landing-zone resources"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.gcp-sg-vpc-hub-001.id
    }
    networks {
      network_url = google_compute_network.gcp-sg-vpc-shared-001.id
    }
  }
}

# Add internal DNS records here as workload services are deployed.
