# Hierarchical (org-level) firewall policy — baseline guardrails evaluated above per-VPC rules

resource "google_compute_firewall_policy" "gcp-sg-org-fw-policy-001" {
  parent      = "organizations/${var.org_id}"
  short_name  = "gcp-sg-org-fw-policy-001"
  description = "Org-wide baseline firewall policy (landing zone)"
}

resource "google_compute_firewall_policy_association" "gcp-sg-org-fw-policy-assoc-001" {
  firewall_policy   = google_compute_firewall_policy.gcp-sg-org-fw-policy-001.id
  attachment_target = "organizations/${var.org_id}"
  name              = "gcp-sg-org-fw-policy-assoc-001"
}

# Delegate RFC1918 to lower-level (VPC) firewall rules
resource "google_compute_firewall_policy_rule" "gcp-sg-fwp-delegate-rfc1918-ingress-001" {
  firewall_policy = google_compute_firewall_policy.gcp-sg-org-fw-policy-001.id
  description     = "Delegate RFC1918 ingress to VPC firewall rules"
  action          = "goto_next"
  direction       = "INGRESS"
  priority        = 1000

  match {
    layer4_configs {
      ip_protocol = "all"
    }
    src_ip_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
}

resource "google_compute_firewall_policy_rule" "gcp-sg-fwp-delegate-rfc1918-egress-001" {
  firewall_policy = google_compute_firewall_policy.gcp-sg-org-fw-policy-001.id
  description     = "Delegate RFC1918 egress to VPC firewall rules"
  action          = "goto_next"
  direction       = "EGRESS"
  priority        = 1001

  match {
    layer4_configs {
      ip_protocol = "all"
    }
    dest_ip_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
}

# Always allow SSH/RDP from IAP
resource "google_compute_firewall_policy_rule" "gcp-sg-fwp-allow-iap-ssh-rdp-001" {
  firewall_policy = google_compute_firewall_policy.gcp-sg-org-fw-policy-001.id
  description     = "Always allow SSH and RDP from Identity-Aware Proxy"
  action          = "allow"
  direction       = "INGRESS"
  priority        = 1002

  match {
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["22", "3389"]
    }
    src_ip_ranges = ["35.235.240.0/20"]
  }
}

# Always allow Google LB + health-check ranges
resource "google_compute_firewall_policy_rule" "gcp-sg-fwp-allow-google-lb-hc-001" {
  firewall_policy = google_compute_firewall_policy.gcp-sg-org-fw-policy-001.id
  description     = "Always allow Google load balancer and health-check ranges"
  action          = "allow"
  direction       = "INGRESS"
  priority        = 1004

  match {
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["80", "443"]
    }
    src_ip_ranges = [
      "35.191.0.0/16",
      "130.211.0.0/22",
      "209.85.152.0/22",
      "209.85.204.0/22",
    ]
  }
}

# Deny known TOR exit nodes (Threat Intelligence)
resource "google_compute_firewall_policy_rule" "gcp-sg-fwp-deny-tor-ingress-001" {
  firewall_policy = google_compute_firewall_policy.gcp-sg-org-fw-policy-001.id
  description     = "Deny ingress from TOR exit nodes"
  action          = "deny"
  direction       = "INGRESS"
  priority        = 1005

  match {
    layer4_configs {
      ip_protocol = "all"
    }
    src_threat_intelligences = ["iplist-tor-exit-nodes"]
  }
}
