# Outputs — consumed by the workload and management stacks via remote_state

output "vpc_shared_access_id" {
  value = google_compute_network.gcp-sg-vpc-shared-access-001.id
}

output "snet_shared_access_id" {
  value = google_compute_subnetwork.gcp-sg-snet-shared-access-001.id
}

# Static external IP — re-used by workload (bastion VM) and management (uptime check)
output "bastion_public_ip" {
  value = google_compute_address.gcp-sg-bastion-ip-001.address
}
