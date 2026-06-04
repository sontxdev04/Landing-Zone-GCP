# =============================================================================
# CONNECTIVITY · Firewall cấp VPC (Tầng 2)
# -----------------------------------------------------------------------------
# Mục đích : Quy tắc firewall cấp VPC, chạy SAU hierarchical policy cấp Org.
#            SSH/RDP qua IAP (35.235.240.0/20) đã được cho phép toàn Org ở
#            priority 1002 (security/org-fw-policies.tf).
# =============================================================================

# VPN: mạng on-prem → Hub VPC (lưu lượng qua HA VPN tunnel)
# Conditional — chỉ tạo khi có khai báo dải on-prem.
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

# Nội bộ: Shared VPC prod — cho phép lưu lượng trong dải workload
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
