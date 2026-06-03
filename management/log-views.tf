# Scoped log views over the central platform log bucket

# View: astronomy-shop workload logs
resource "google_logging_log_view" "gcp-sg-logview-astronomy-shop-001" {
  name        = "gcp-sg-logview-astronomy-shop-001"
  bucket      = trimprefix(module.gcp-sg-logbkt-fldr-platform-001.destination_uri, "logging.googleapis.com/")
  description = "Log view scoped to the astronomy-shop workload project"
  filter      = "SOURCE(\"projects/${local.org.project_id_astronomy_shop}\")"

  depends_on = [module.gcp-sg-logbkt-fldr-platform-001]
}

# View: hub network project logs
resource "google_logging_log_view" "gcp-sg-logview-hub-net-001" {
  name        = "gcp-sg-logview-hub-net-001"
  bucket      = trimprefix(module.gcp-sg-logbkt-fldr-platform-001.destination_uri, "logging.googleapis.com/")
  description = "Log view scoped to the hub network project"
  filter      = "SOURCE(\"projects/${local.org.project_id_hub_net}\")"

  depends_on = [module.gcp-sg-logbkt-fldr-platform-001]
}
