# Workload stack — compute resources for workload projects
#
# SSH Access via Cloud IAP (no bastion host, no external IPs needed):
#   gcloud compute ssh <INSTANCE_NAME> \
#     --project=<PROJECT_ID> \
#     --zone=asia-southeast1-b \
#     --tunnel-through-iap
#
# Prerequisites:
#   1. User must have roles/iap.tunnelResourceAccessor on the project (granted in security/iam.tf)
#   2. OS Login must be enabled (enforced org-wide via org policy)
#   3. The org-level firewall policy already allows IAP range (35.235.240.0/20) on port 22

# Add your workload VMs below.
# Example skeleton (astronomy-shop app VM):
#
# resource "google_compute_instance" "gcp-sg-vm-astronomy-shop-001" {
#   name         = "gcp-sg-vm-astronomy-shop-001"
#   machine_type = "e2-standard-2"
#   zone         = "asia-southeast1-b"
#   project      = local.org.project_id_astronomy_shop
#
#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-12"
#       size  = 50
#       type  = "pd-standard"
#     }
#   }
#
#   network_interface {
#     network            = local.conn.vpc_shared_access_id   # or snet_app_id
#     subnetwork         = local.conn.snet_shared_access_id
#     subnetwork_project = local.org.project_id_sh_vpc
#     # No access_config block = no external IP (IAP handles access)
#   }
#
#   shielded_instance_config {
#     enable_secure_boot          = true
#     enable_vtpm                 = true
#     enable_integrity_monitoring = true
#   }
#
#   metadata = { enable-oslogin = "TRUE" }
#   tags     = ["app-vm"]
#   labels = {
#     managed_by  = "terraform"
#     stack       = "workload"
#     environment = "prod"
#   }
# }
