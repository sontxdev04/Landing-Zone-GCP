# =============================================================================
# CONNECTIVITY · Cloud NAT
# -----------------------------------------------------------------------------
# Mục đích : Cấp đường egress ra Internet cho VM không có IP ngoài.
#            Một chiều (egress-only) — Internet không thể chủ động kết nối vào.
#            Cloud Router đặt ở routers.tf.
# =============================================================================

# Cloud NAT cho subnet app (prod) — egress Internet cho VM nội bộ
resource "google_compute_router_nat" "gcp-sg-nat-001" {
  name                               = "gcp-sg-nat-001"
  project                            = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  router                             = google_compute_router.gcp-sg-router-nat-001.name
  region                             = "asia-southeast1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.gcp-sg-snet-app-001.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
