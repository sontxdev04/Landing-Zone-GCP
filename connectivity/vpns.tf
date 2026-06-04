# HA VPN — hub VPC to on-premises BGP over two redundant tunnels

locals {
  vpn_enabled = (
    var.onprem_vpn_public_ip_0 != "" &&
    var.onprem_vpn_public_ip_1 != "" &&
    var.vpn_shared_secret_1 != "" &&
    var.vpn_shared_secret_2 != ""
  ) ? 1 : 0
}

# HA VPN Gateway in hub VPC
resource "google_compute_ha_vpn_gateway" "gcp-sg-vpn-hub-001" {
  count   = local.vpn_enabled
  name    = "gcp-sg-vpn-hub-001"
  project = data.google_project.gcp-sg-prj-hub-net-001.project_id
  region  = "asia-southeast1"
  network = google_compute_network.gcp-sg-vpc-hub-001.id
}

# External VPN Gateway representing on-prem peer
resource "google_compute_external_vpn_gateway" "gcp-sg-vpn-external-peer-001" {
  count           = local.vpn_enabled
  name            = "gcp-sg-vpn-external-peer-001"
  project         = data.google_project.gcp-sg-prj-hub-net-001.project_id
  redundancy_type = "TWO_IPS_REDUNDANCY"
  description     = "External on-premises VPN peer gateway"

  interface {
    id         = 0
    ip_address = var.onprem_vpn_public_ip_0
  }

  interface {
    id         = 1
    ip_address = var.onprem_vpn_public_ip_1
  }
}

# VPN Tunnel 0 (HA VPN iface 0 <-> peer iface 0)
resource "google_compute_vpn_tunnel" "gcp-sg-vpn-tunnel-001" {
  count                           = local.vpn_enabled
  name                            = "gcp-sg-vpn-tunnel-001"
  project                         = data.google_project.gcp-sg-prj-hub-net-001.project_id
  region                          = "asia-southeast1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp-sg-vpn-hub-001[0].id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp-sg-vpn-external-peer-001[0].id
  peer_external_gateway_interface = 0
  shared_secret                   = var.vpn_shared_secret_1
  router                          = google_compute_router.gcp-sg-router-hub-001.id
}

# VPN Tunnel 1 (HA VPN iface 1 <-> peer iface 1)
resource "google_compute_vpn_tunnel" "gcp-sg-vpn-tunnel-002" {
  count                           = local.vpn_enabled
  name                            = "gcp-sg-vpn-tunnel-002"
  project                         = data.google_project.gcp-sg-prj-hub-net-001.project_id
  region                          = "asia-southeast1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp-sg-vpn-hub-001[0].id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp-sg-vpn-external-peer-001[0].id
  peer_external_gateway_interface = 1
  shared_secret                   = var.vpn_shared_secret_2
  router                          = google_compute_router.gcp-sg-router-hub-001.id
}

# BGP interface for tunnel 0
# count mirrors the tunnel — body executes only when vpn_enabled=1, so [0] is safe.
resource "google_compute_router_interface" "gcp-sg-router-interface-001" {
  count      = length(google_compute_vpn_tunnel.gcp-sg-vpn-tunnel-001)
  name       = "gcp-sg-router-interface-001"
  project    = data.google_project.gcp-sg-prj-hub-net-001.project_id
  router     = google_compute_router.gcp-sg-router-hub-001.name
  region     = "asia-southeast1"
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.gcp-sg-vpn-tunnel-001[0].name
  depends_on = [google_compute_vpn_tunnel.gcp-sg-vpn-tunnel-001]
}

# BGP peer for tunnel 0
resource "google_compute_router_peer" "gcp-sg-router-peer-001" {
  count                     = length(google_compute_vpn_tunnel.gcp-sg-vpn-tunnel-001)
  name                      = "gcp-sg-router-peer-001"
  project                   = data.google_project.gcp-sg-prj-hub-net-001.project_id
  router                    = google_compute_router.gcp-sg-router-hub-001.name
  region                    = "asia-southeast1"
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = 65002
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp-sg-router-interface-001[0].name
  depends_on                = [google_compute_router_interface.gcp-sg-router-interface-001]
}

# BGP interface for tunnel 1
# count mirrors the tunnel — body executes only when vpn_enabled=1, so [0] is safe.
resource "google_compute_router_interface" "gcp-sg-router-interface-002" {
  count      = length(google_compute_vpn_tunnel.gcp-sg-vpn-tunnel-002)
  name       = "gcp-sg-router-interface-002"
  project    = data.google_project.gcp-sg-prj-hub-net-001.project_id
  router     = google_compute_router.gcp-sg-router-hub-001.name
  region     = "asia-southeast1"
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.gcp-sg-vpn-tunnel-002[0].name
  depends_on = [google_compute_router_interface.gcp-sg-router-interface-001, google_compute_vpn_tunnel.gcp-sg-vpn-tunnel-002]
}

# BGP peer for tunnel 1
resource "google_compute_router_peer" "gcp-sg-router-peer-002" {
  count                     = length(google_compute_vpn_tunnel.gcp-sg-vpn-tunnel-002)
  name                      = "gcp-sg-router-peer-002"
  project                   = data.google_project.gcp-sg-prj-hub-net-001.project_id
  router                    = google_compute_router.gcp-sg-router-hub-001.name
  region                    = "asia-southeast1"
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 65002
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp-sg-router-interface-002[0].name
  depends_on                = [google_compute_router_interface.gcp-sg-router-interface-002]
}
