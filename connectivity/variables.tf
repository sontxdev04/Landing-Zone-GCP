# Service account that Terraform impersonates when applying this stack (created manually — see README §6.1).
variable "tf_runner_sa" {
  description = "Email of the TF Runner SA dedicated to the connectivity stack"
  type        = string
}

variable "onprem_vpn_public_ip_0" {
  description = "Public IP of the on-premises VPN gateway (interface 0)"
  type        = string
  default     = ""
}

variable "onprem_vpn_public_ip_1" {
  description = "Public IP of the on-premises VPN gateway (interface 1)"
  type        = string
  default     = ""
}

variable "vpn_shared_secret_1" {
  description = "Shared secret for HA VPN Tunnel 1"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vpn_shared_secret_2" {
  description = "Shared secret for HA VPN Tunnel 2"
  type        = string
  sensitive   = true
  default     = ""
}

variable "onprem_network_cidrs" {
  description = "On-premises network CIDR ranges reaching the hub VPC over the HA VPN tunnel"
  type        = list(string)
  default     = []
}
