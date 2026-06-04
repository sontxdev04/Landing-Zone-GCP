# =============================================================================
# CONNECTIVITY · Biến đầu vào của stack
# -----------------------------------------------------------------------------
# Mục đích : Khai báo runner SA và các tham số VPN/on-prem. Khi các giá trị
#            VPN để trống, toàn bộ tài nguyên VPN bị bỏ qua (xem vpns.tf).
# =============================================================================

# SA mà Terraform mạo danh khi apply stack này (tạo thủ công — xem README §6.1).
variable "tf_runner_sa" {
  description = "Email của TF Runner SA dành riêng cho stack connectivity"
  type        = string
}

variable "onprem_vpn_public_ip_0" {
  description = "IP công khai của VPN gateway on-premises (interface 0)"
  type        = string
  default     = ""
}

variable "onprem_vpn_public_ip_1" {
  description = "IP công khai của VPN gateway on-premises (interface 1)"
  type        = string
  default     = ""
}

variable "vpn_shared_secret_1" {
  description = "Shared secret cho HA VPN Tunnel 1"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vpn_shared_secret_2" {
  description = "Shared secret cho HA VPN Tunnel 2"
  type        = string
  sensitive   = true
  default     = ""
}

variable "onprem_network_cidrs" {
  description = "Các dải CIDR mạng on-premises đến được hub VPC qua HA VPN tunnel"
  type        = list(string)
  default     = []
}
