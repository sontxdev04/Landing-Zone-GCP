# Static external IP addresses — owned by the Network team

# Bastion Host static external IP (consumed by the workload stack's bastion VM)
resource "google_compute_address" "gcp-sg-bastion-ip-001" {
  name         = "gcp-sg-bastion-ip-001"
  project      = data.google_project.gcp-sg-prj-sh-access-001.project_id
  region       = "asia-southeast1"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}
