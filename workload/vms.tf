# =============================================================================
# WORKLOAD · Compute — VM mẫu cho project workload
# -----------------------------------------------------------------------------
# Mục đích : Tạo VM mẫu gắn Shared VPC (không IP public) để dashboard
#            monitoring có dữ liệu. Bật/tắt qua biến enable_sample_vm.
# -----------------------------------------------------------------------------
# SSH qua Cloud IAP (không cần bastion host, không cần IP ngoài):
#   gcloud compute ssh <INSTANCE_NAME> \
#     --project=<PROJECT_ID> \
#     --zone=asia-southeast1-b \
#     --tunnel-through-iap
#
# Điều kiện tiên quyết:
#   1. User cần roles/iap.tunnelResourceAccessor trên project (cấp ở security/iam.tf)
#   2. OS Login được bật (bắt buộc toàn Org qua org policy)
#   3. Hierarchical firewall policy đã cho phép dải IAP (35.235.240.0/20) trên port 22
# =============================================================================

# Runtime SA gắn vào VM: gcp-sg-sa-sample-app-001 (tạo ở scripts/03-runtime-sa.sh,
# đã có sẵn roles/monitoring.metricWriter + roles/logging.logWriter). KHÔNG dùng
# default compute SA vì project-factory đã deprivilege/disable nó (least-privilege)
# → nếu để VM tự gắn default SA, Ops Agent sẽ không lấy được token và metric
# memory/disk không gửi lên được.
resource "google_compute_instance" "gcp-sg-vm-sample-app-001" {
  count        = var.enable_sample_vm ? 1 : 0
  name         = "gcp-sg-vm-sample-app-001"
  machine_type = "e2-small"
  zone         = "asia-southeast1-b"
  project      = local.org.project_id_sample_app

  # Cho phép Terraform tự stop/start VM khi đổi các thuộc tính yêu cầu dừng máy
  # (vd: service_account, machine_type). An toàn với VM mẫu.
  allow_stopping_for_update = true

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

  # Gắn runtime SA (không phải default compute SA đã bị disable). Scope cloud-platform
  # để Ops Agent dùng IAM của SA — quyền thực tế bị giới hạn bởi role của SA.
  service_account {
    email  = "gcp-sg-sa-sample-app-001@${local.org.project_id_sample_app}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
    # Cài Google Cloud Ops Agent để xuất metric memory/disk lên Cloud Monitoring.
    # Dùng URL repo chính thức + retry: tại thời điểm boot, Cloud NAT có thể chưa
    # sẵn sàng ngay nên curl được retry vài lần để tránh tải nhầm trang lỗi.
    startup-script = <<-EOT
      #!/bin/bash
      set -euo pipefail
      curl --retry 5 --retry-connrefused --retry-delay 10 -fsSO \
        https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
      sudo bash add-google-cloud-ops-agent-repo.sh --also-install
    EOT
  }

  tags = ["app-vm"]
  labels = {
    managed_by  = "terraform"
    stack       = "workload"
    environment = "prod"
  }
}
