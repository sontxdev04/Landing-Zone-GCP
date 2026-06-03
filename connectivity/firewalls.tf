# Firewall rules — owned by the Network team (references VPCs in this stack)

# SSH: Internet → Bastion
resource "google_compute_firewall" "gcp-sg-fw-allow-ssh-bastion-001" {
  name          = "gcp-sg-fw-allow-ssh-bastion-001"
  project       = data.google_project.gcp-sg-prj-sh-access-001.project_id
  network       = google_compute_network.gcp-sg-vpc-shared-access-001.name
  description   = "Allow SSH from internet to Bastion Host"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh-external"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# SSH: Bastion → app VMs (tag your workload VMs with "app-vm")
resource "google_compute_firewall" "gcp-sg-fw-allow-bastion-ssh-001" {
  name          = "gcp-sg-fw-allow-bastion-ssh-001"
  project       = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  network       = google_compute_network.gcp-sg-vpc-shared-001.name
  description   = "Allow SSH from Bastion to app VMs"
  source_ranges = ["10.50.1.100/32"]
  target_tags   = ["app-vm"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# VPN: On-prem networks → Hub VPC (traffic over HA VPN tunnel)
resource "google_compute_firewall" "gcp-sg-fw-allow-vpn-hub-001" {
  count         = length(var.onprem_network_cidrs) > 0 ? 1 : 0
  name          = "gcp-sg-fw-allow-vpn-hub-001"
  project       = data.google_project.gcp-sg-prj-hub-net-001.project_id
  network       = google_compute_network.gcp-sg-vpc-hub-001.name
  description   = "Allow traffic from on-prem networks into the hub VPC via HA VPN"
  source_ranges = var.onprem_network_cidrs
  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }
}

# Internal: Prod VPC
resource "google_compute_firewall" "gcp-sg-fw-allow-internal-001" {
  name          = "gcp-sg-fw-allow-internal-001"
  project       = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  network       = google_compute_network.gcp-sg-vpc-shared-001.name
  description   = "Allow internal traffic within the app VPC"
  source_ranges = ["10.20.0.0/20"]
  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }
  allow { protocol = "ipip" }
}
