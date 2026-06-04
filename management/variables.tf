# =============================================================================
# MANAGEMENT · Biến đầu vào của stack
# -----------------------------------------------------------------------------
# Mục đích : Khai báo Org ID, runner SA, email cảnh báo và billing account
#            cho ngân sách theo tháng.
# =============================================================================

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

# SA mà Terraform mạo danh khi apply stack này (tạo thủ công — xem README §6.1).
variable "tf_runner_sa" {
  description = "Email của TF Runner SA dành riêng cho stack management"
  type        = string
}

# Email nhận cảnh báo Cloud Monitoring và thông báo ngân sách.
variable "alert_notification_email" {
  description = "Địa chỉ email nhận cảnh báo monitoring và ngưỡng ngân sách"
  type        = string
}

# Billing account được ngân sách tháng theo dõi chi tiêu.
# Thường đặt bằng một trong org.billing_account_id_1/_2 (hoặc một account riêng).
variable "budget_billing_account_id" {
  description = "Billing account ID mà ngân sách tháng theo dõi chi tiêu"
  type        = string
}
