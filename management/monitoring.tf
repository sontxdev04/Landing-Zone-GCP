# Centralized monitoring — management project is the single Metrics Scope for all projects

# Data sources — project references
data "google_project" "gcp-sg-prj-management-001" {
  project_id = local.org.project_id_management
}

data "google_project" "gcp-sg-prj-astronomy-shop-001" {
  project_id = local.org.project_id_astronomy_shop
}

data "google_project" "gcp-sg-prj-sh-access-001" {
  project_id = local.org.project_id_sh_access
}

# Metrics Scope — attach all projects' metrics to the management project (management is its own scope already)

resource "google_monitoring_monitored_project" "gcp-sg-metricscope-astronomy-shop-001" {
  metrics_scope = local.org.project_id_management
  name          = local.org.project_id_astronomy_shop
}

resource "google_monitoring_monitored_project" "gcp-sg-metricscope-sh-access-001" {
  metrics_scope = local.org.project_id_management
  name          = local.org.project_id_sh_access
}

resource "google_monitoring_monitored_project" "gcp-sg-metricscope-hub-net-001" {
  metrics_scope = local.org.project_id_management
  name          = local.org.project_id_hub_net
}

resource "google_monitoring_monitored_project" "gcp-sg-metricscope-sh-vpc-001" {
  metrics_scope = local.org.project_id_management
  name          = local.org.project_id_sh_vpc
}

# Notification channels (central — management project)

resource "google_monitoring_notification_channel" "gcp-sg-monitoring-email-001" {
  display_name = "gcp-sg-monitoring-email-001"
  type         = "email"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  labels = {
    email_address = var.alert_notification_email
  }
}

# Uptime check — Bastion SSH (central; host comes from workload stack output)

resource "google_monitoring_uptime_check_config" "gcp-sg-uptime-bastion-001" {
  display_name = "gcp-sg-uptime-bastion-001"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  timeout      = "10s"
  period       = "60s"

  tcp_check {
    port = 22
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = data.google_project.gcp-sg-prj-sh-access-001.project_id
      host       = local.wl.bastion_public_ip
    }
  }
}

# Alert: Bastion uptime check failing
resource "google_monitoring_alert_policy" "gcp-sg-alert-uptime-bastion-001" {
  display_name = "gcp-sg-alert-uptime-bastion-001"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  combiner     = "OR"

  conditions {
    display_name = "Bastion uptime check failing"
    condition_threshold {
      filter          = "metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id = \"${google_monitoring_uptime_check_config.gcp-sg-uptime-bastion-001.uptime_check_id}\" AND resource.type = \"uptime_url\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      trigger {
        count = 1
      }

      aggregations {
        alignment_period     = "1200s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.project_id", "resource.label.host"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.gcp-sg-monitoring-email-001.name]

  alert_strategy {
    auto_close = "604800s"
  }
}

# Alert: VM CPU > 80% for 5 minutes (prod env)
resource "google_monitoring_alert_policy" "gcp-sg-alert-cpu-001" {
  display_name = "gcp-sg-alert-cpu-001"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  combiner     = "OR"

  conditions {
    display_name = "VM CPU > 80%"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\" AND resource.labels.project_id = \"${data.google_project.gcp-sg-prj-astronomy-shop-001.project_id}\""
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

  depends_on = [google_monitoring_monitored_project.gcp-sg-metricscope-astronomy-shop-001]
}

# Alert: VM memory > 80% (requires Ops Agent on the instance)
resource "google_monitoring_alert_policy" "gcp-sg-alert-memory-001" {
  display_name = "gcp-sg-alert-memory-001"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  combiner     = "OR"

  conditions {
    display_name = "VM memory > 80%"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/memory/percent_used\" AND metric.label.state = \"used\" AND resource.labels.project_id = \"${data.google_project.gcp-sg-prj-astronomy-shop-001.project_id}\""
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

  depends_on = [google_monitoring_monitored_project.gcp-sg-metricscope-astronomy-shop-001]
}

# Alert: VM disk > 85% (requires Ops Agent on the instance)
resource "google_monitoring_alert_policy" "gcp-sg-alert-disk-001" {
  display_name = "gcp-sg-alert-disk-001"
  project      = data.google_project.gcp-sg-prj-management-001.project_id
  combiner     = "OR"

  conditions {
    display_name = "VM disk > 85%"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/disk/percent_used\" AND metric.label.state = \"used\" AND resource.labels.project_id = \"${data.google_project.gcp-sg-prj-astronomy-shop-001.project_id}\""
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

  depends_on = [google_monitoring_monitored_project.gcp-sg-metricscope-astronomy-shop-001]
}
