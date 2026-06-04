# Monthly billing budget with threshold alerts (skipped when budget_billing_account_id is empty)

resource "google_billing_budget" "gcp-sg-budget-monthly-001" {
  count           = var.budget_billing_account_id != "" ? 1 : 0
  billing_account = var.budget_billing_account_id
  display_name    = "gcp-sg-budget-monthly-001"

  budget_filter {
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = "VND"     # phai khop currency cua billing account (VND), neu khong API tra 400
      units         = "2500000" # ~100 USD/thang
    }
  }

  dynamic "threshold_rules" {
    for_each = toset([0.5, 0.8, 1.0])
    content {
      threshold_percent = threshold_rules.value
      spend_basis       = "CURRENT_SPEND"
    }
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.gcp-sg-monitoring-email-001.id]
    disable_default_iam_recipients   = false
  }
}
