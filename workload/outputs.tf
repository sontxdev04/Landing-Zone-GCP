output "bastion_public_ip" {
  description = "Public IP of Bastion Host (owned by connectivity; re-exported for monitoring uptime check)"
  value       = local.conn.bastion_public_ip
}
