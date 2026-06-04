# =============================================================================
# WORKLOAD · Biến đầu vào của stack
# -----------------------------------------------------------------------------
# Mục đích : Khai báo runner SA và cờ bật/tắt VM mẫu.
# =============================================================================

# SA mà Terraform mạo danh khi apply stack này (tạo thủ công — xem README §6.1).
variable "tf_runner_sa" {
  description = "Email của TF Runner SA dành riêng cho stack workload"
  type        = string
}

# Bật/tắt VM mẫu. Mặc định true để dashboard monitoring có dữ liệu hiển thị.
variable "enable_sample_vm" {
  description = "Tạo VM mẫu (e2-small) trong project sample-app để dashboard monitoring có metric. Đặt false để bỏ qua."
  type        = bool
  default     = true
}
