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
