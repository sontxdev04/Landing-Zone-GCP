# =============================================================================
# SECURITY · Biến đầu vào của stack
# -----------------------------------------------------------------------------
# Mục đích : Khai báo org id, runner SA và danh sách principal nhận quyền admin.
# =============================================================================
variable "org_id" {
  description = "ID của GCP Organization"
  type        = string
}

# SA mà Terraform mạo danh khi apply stack này (tạo thủ công — xem README §6.1).
variable "tf_runner_sa" {
  description = "Email của TF Runner SA dành riêng cho stack security"
  type        = string
}

# Nhận principal IAM đầy đủ tiền tố, ví dụ "group:grp-sre@company.com" hoặc "user:alice@company.com".
variable "admin_principals" {
  description = "Các principal IAM (ưu tiên group) nhận quyền admin cấp org"
  type        = list(string)
}
