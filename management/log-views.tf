# =============================================================================
# MANAGEMENT · Log views
# -----------------------------------------------------------------------------
# Mục đích : Các log view giới hạn phạm vi trên log bucket platform tập trung.
# =============================================================================

# View: log workload sample-app
resource "google_logging_log_view" "gcp-sg-logview-sample-app-001" {
  name        = "gcp-sg-logview-sample-app-001"
  bucket      = trimprefix(module.gcp-sg-logbkt-fldr-platform-001.destination_uri, "logging.googleapis.com/")
  description = "Log view giới hạn trong project workload sample-app"
  filter      = "SOURCE(\"projects/${local.org.project_id_sample_app}\")"

  depends_on = [module.gcp-sg-logbkt-fldr-platform-001]
}

# View: log project hub network
resource "google_logging_log_view" "gcp-sg-logview-hub-net-001" {
  name        = "gcp-sg-logview-hub-net-001"
  bucket      = trimprefix(module.gcp-sg-logbkt-fldr-platform-001.destination_uri, "logging.googleapis.com/")
  description = "Log view giới hạn trong project hub network"
  filter      = "SOURCE(\"projects/${local.org.project_id_hub_net}\")"

  depends_on = [module.gcp-sg-logbkt-fldr-platform-001]
}
