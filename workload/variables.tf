# Service account that Terraform impersonates when applying this stack (created manually — see README §6.1).
variable "tf_runner_sa" {
  description = "Email of the TF Runner SA dedicated to the workload stack"
  type        = string
}

# Bật/tắt VM mẫu. Mặc định true để dashboard monitoring có dữ liệu hiển thị.
variable "enable_sample_vm" {
  description = "Tạo VM mẫu (e2-small) trong project sample-app để dashboard monitoring có metric. Đặt false để bỏ qua."
  type        = bool
  default     = true
}
