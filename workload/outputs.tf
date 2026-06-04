# Workload stack outputs
# NOTE: bastion_public_ip removed — bastion host replaced by Cloud IAP.

output "sample_vm_name" {
  description = "Tên VM mẫu (null nếu enable_sample_vm=false)"
  value       = var.enable_sample_vm ? google_compute_instance.gcp-sg-vm-sample-app-001[0].name : null
}

output "sample_vm_internal_ip" {
  description = "IP nội bộ của VM mẫu (truy cập qua Cloud IAP, không có IP public)"
  value       = var.enable_sample_vm ? google_compute_instance.gcp-sg-vm-sample-app-001[0].network_interface[0].network_ip : null
}
