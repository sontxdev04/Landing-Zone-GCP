# =============================================================================
# ORG · Biến đầu vào của stack
# -----------------------------------------------------------------------------
# Mục đích : Khai báo các biến cấp Organization (org id, runner SA, billing).
# =============================================================================
variable "org_id" {
  description = "ID của GCP Organization"
  type        = string
}

# SA mà Terraform mạo danh khi apply stack này (tạo thủ công — xem README §6.1).
variable "tf_runner_sa" {
  description = "Email của TF Runner SA dành riêng cho stack org"
  type        = string
}

variable "billing_account_id_1" {
  description = "Billing account 1 — dùng cho project platform management & security"
  type        = string
}

variable "billing_account_id_2" {
  description = "Billing account 2 — dùng cho project networking & workload"
  type        = string
}

