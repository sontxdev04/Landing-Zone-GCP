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

# VM mẫu — gắn vào Shared VPC (không IP public), cài Ops Agent để dashboard
# monitoring (CPU/memory/disk) có dữ liệu. Bật/tắt qua biến enable_sample_vm.
# Lưu ý: VM dùng Compute Engine default SA với scope mặc định (đã có quyền ghi
# monitoring/logging). Nếu org chặn default SA grants, cần cấp cho SA của VM hai
# role roles/monitoring.metricWriter và roles/logging.logWriter để Ops Agent gửi metric.
resource "google_compute_instance" "gcp-sg-vm-sample-app-001" {
  count        = var.enable_sample_vm ? 1 : 0
  name         = "gcp-sg-vm-sample-app-001"
  machine_type = "e2-small"
  zone         = "asia-southeast1-b"
  project      = local.org.project_id_sample_app

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    # Subnet self_link đã bao gồm host project → đủ cho Shared VPC service project.
    subnetwork         = local.conn.snet_app_self_link
    subnetwork_project = local.conn.project_id_sh_vpc
    # Không có access_config = không IP public (egress qua Cloud NAT, truy cập qua IAP).
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
    # Cài Google Cloud Ops Agent để xuất metric memory/disk lên Cloud Monitoring.
    startup-script = <<-EOT
      #!/bin/bash
      curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent.sh
      sudo bash add-google-cloud-ops-agent.sh --also-install
    EOT
  }

  tags = ["app-vm"]
  labels = {
    managed_by  = "terraform"
    stack       = "workload"
    environment = "prod"
  }
}
