# Cloud Monitoring dashboards (Ops/Monitoring team) — simple common views

# Dashboard: Infrastructure Overview — VM CPU / Memory / Disk / Network
resource "google_monitoring_dashboard" "gcp-sg-dashboard-infra-001" {
  project = data.google_project.gcp-sg-prj-management-001.project_id

  dashboard_json = jsonencode({
    displayName = "gcp-sg-dashboard-infra-001 — Infrastructure Overview"
    gridLayout = {
      columns = 2
      widgets = [
        {
          title = "VM CPU Utilization"
          xyChart = {
            dataSets = [{
              plotType = "LINE"
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter      = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                  aggregation = { alignmentPeriod = "60s", perSeriesAligner = "ALIGN_MEAN" }
                }
              }
            }]
            yAxis = { label = "CPU", scale = "LINEAR" }
          }
        },
        {
          title = "VM Memory Used (%)"
          xyChart = {
            dataSets = [{
              plotType = "LINE"
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter      = "resource.type=\"gce_instance\" AND metric.type=\"agent.googleapis.com/memory/percent_used\" AND metric.label.state=\"used\""
                  aggregation = { alignmentPeriod = "60s", perSeriesAligner = "ALIGN_MEAN" }
                }
              }
            }]
            yAxis = { label = "Memory %", scale = "LINEAR" }
          }
        },
        {
          title = "VM Disk Used (%)"
          xyChart = {
            dataSets = [{
              plotType = "LINE"
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter      = "resource.type=\"gce_instance\" AND metric.type=\"agent.googleapis.com/disk/percent_used\" AND metric.label.state=\"used\""
                  aggregation = { alignmentPeriod = "60s", perSeriesAligner = "ALIGN_MEAN" }
                }
              }
            }]
            yAxis = { label = "Disk %", scale = "LINEAR" }
          }
        },
        {
          title = "VM Network Received (bytes/s)"
          xyChart = {
            dataSets = [{
              plotType = "LINE"
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter      = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/network/received_bytes_count\""
                  aggregation = { alignmentPeriod = "60s", perSeriesAligner = "ALIGN_RATE" }
                }
              }
            }]
            yAxis = { label = "Bytes/s", scale = "LINEAR" }
          }
        },
      ]
    }
  })
}

# Dashboard: Availability — uptime check pass ratio
resource "google_monitoring_dashboard" "gcp-sg-dashboard-availability-001" {
  project = data.google_project.gcp-sg-prj-management-001.project_id

  dashboard_json = jsonencode({
    displayName = "gcp-sg-dashboard-availability-001 — Availability"
    gridLayout = {
      columns = 1
      widgets = [
        {
          title = "Bastion Uptime Check (passed)"
          xyChart = {
            dataSets = [{
              plotType = "LINE"
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter      = "resource.type=\"uptime_url\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
                  aggregation = { alignmentPeriod = "300s", perSeriesAligner = "ALIGN_FRACTION_TRUE" }
                }
              }
            }]
            yAxis = { label = "Pass ratio", scale = "LINEAR" }
          }
        },
      ]
    }
  })
}
