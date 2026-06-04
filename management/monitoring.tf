# =============================================================================
# MANAGEMENT · Monitoring tập trung
# -----------------------------------------------------------------------------
# Mục đích : Project management là Metrics Scope duy nhất cho tất cả project;
#            khai báo kênh thông báo và các alert policy CPU/memory/disk.
# =============================================================================

# Data source — tham chiếu project
data "google_project" "gcp-sg-prj-management-001" {
  project_id = local.org.project_id_management
}

data "google_project" "gcp-sg-prj-sample-app-001" {
  project_id = local.org.project_id_sample_app
}

# Metrics Scope — gắn metric của mọi project vào project management
# (bản thân management đã là scope riêng)

resource "google_monitoring_monitored_project" "gcp-sg-metricscope-sample-app-001" {
  metrics_scope = local.org.project_id_management
  name          = local.org.project_id_sample_app
}


resource "google_monitoring_monitored_project" "gcp-sg-metricscope-hub-net-001" {
  metrics_scope = local.org.project_id_management
  name          = local.org.project_id_hub_net
}

resource "google_monitoring_monitored_project" "gcp-sg-metricscope-sh-vpc-001" {
  metrics_scope = local.org.project_id_management
  name          = local.org.project_id_sh_vpc
}

# Kênh thông báo (tập trung — project management)

resource "google_monitoring_notification_channel" "gcp-sg-monitoring-email-001" {
  display_name = "gcp-sg-monitoring-email-001"
  type         = "email"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  labels = {
    email_address = var.alert_notification_email
  }
}

# Alert: VM CPU > 80% trong 5 phút (môi trường prod)
resource "google_monitoring_alert_policy" "gcp-sg-alert-cpu-001" {
  display_name = "gcp-sg-alert-cpu-001"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  combiner     = "OR"

  conditions {
    display_name = "VM CPU > 80%"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\" AND resource.labels.project_id = \"${data.google_project.gcp-sg-prj-sample-app-001.project_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.gcp-sg-monitoring-email-001.name]

  alert_strategy {
    auto_close = "604800s"
  }

  depends_on = [google_monitoring_monitored_project.gcp-sg-metricscope-sample-app-001]
}

# Alert: VM memory > 80% (cần Ops Agent trên instance)
resource "google_monitoring_alert_policy" "gcp-sg-alert-memory-001" {
  display_name = "gcp-sg-alert-memory-001"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  combiner     = "OR"

  conditions {
    display_name = "VM memory > 80%"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/memory/percent_used\" AND metric.label.state = \"used\" AND resource.labels.project_id = \"${data.google_project.gcp-sg-prj-sample-app-001.project_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 80

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.gcp-sg-monitoring-email-001.name]

  alert_strategy {
    auto_close = "604800s"
  }

  depends_on = [google_monitoring_monitored_project.gcp-sg-metricscope-sample-app-001]
}

# Alert: VM disk > 85% (cần Ops Agent trên instance)
resource "google_monitoring_alert_policy" "gcp-sg-alert-disk-001" {
  display_name = "gcp-sg-alert-disk-001"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  combiner     = "OR"

  conditions {
    display_name = "VM disk > 85%"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/disk/percent_used\" AND metric.label.state = \"used\" AND resource.labels.project_id = \"${data.google_project.gcp-sg-prj-sample-app-001.project_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 85

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.gcp-sg-monitoring-email-001.name]

  alert_strategy {
    auto_close = "604800s"
  }

  depends_on = [google_monitoring_monitored_project.gcp-sg-metricscope-sample-app-001]
}
