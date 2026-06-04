# =============================================================================
# MANAGEMENT · Xuất log tập trung
# -----------------------------------------------------------------------------
# Mục đích : Sink log cấp org + folder về project management (hot 90 ngày)
#            và lưu trữ GCS (archive 365 ngày).
# =============================================================================

locals {
  central_logging_project = local.org.project_id_management
  audit_archive_project   = local.org.project_id_management
  log_region              = "asia-southeast1"
}

# Log cấp Organization → hot log bucket
module "gcp-sg-logexp-org-001" {
  source  = "terraform-google-modules/log-export/google"
  version = "10.0.0"

  log_sink_name        = "gcp-sg-logexp-org-001"
  parent_resource_type = "organization"
  parent_resource_id   = var.org_id
  include_children     = true
  destination_uri      = module.gcp-sg-logbkt-org-001.destination_uri

  filter = <<-EOT
    log_id("cloudaudit.googleapis.com/activity")
    OR log_id("cloudaudit.googleapis.com/data_access")
    OR log_id("cloudaudit.googleapis.com/system_event")
    OR log_id("cloudaudit.googleapis.com/policy")
    OR log_id("dns.googleapis.com/dns_queries")
    OR (log_id("compute.googleapis.com/firewall") AND resource.type="gce_subnetwork")
    OR (log_id("compute.googleapis.com/vpc_flows") AND resource.type="gce_subnetwork")
    OR (log_id("requests") AND resource.type="http_load_balancer")
    OR (log_id("syslog") AND resource.type="gce_instance")
  EOT
}

module "gcp-sg-logbkt-org-001" {
  source  = "terraform-google-modules/log-export/google//modules/logbucket"
  version = "10.0.0"

  name                     = "gcp-sg-logbkt-org-001"
  project_id               = local.central_logging_project
  location                 = local.log_region
  retention_days           = 90
  log_sink_writer_identity = module.gcp-sg-logexp-org-001.writer_identity
}

# Log cấp Organization → GCS archive (cold)
module "gcp-sg-logexp-org-gcs-001" {
  source  = "terraform-google-modules/log-export/google"
  version = "10.0.0"

  log_sink_name        = "gcp-sg-logexp-org-gcs-001"
  parent_resource_type = "organization"
  parent_resource_id   = var.org_id
  include_children     = true
  destination_uri      = module.gcp-sg-gcsbkt-log-org-001.destination_uri

  filter = "log_id(\"cloudaudit.googleapis.com/activity\") OR log_id(\"cloudaudit.googleapis.com/system_event\") OR log_id(\"cloudaudit.googleapis.com/policy\")"
}

module "gcp-sg-gcsbkt-log-org-001" {
  source  = "terraform-google-modules/log-export/google//modules/storage"
  version = "10.0.0"

  storage_bucket_name = "${local.org.prefix}-logbkt-gcs-${local.org.name_suffix}"
  project_id          = local.audit_archive_project
  location            = local.log_region
  storage_class       = "ARCHIVE"

  uniform_bucket_level_access = true
  versioning                  = true

  lifecycle_rules = [
    {
      action = { type = "Delete" }
      condition = {
        age        = 365
        with_state = "ANY"
      }
    },
  ]

  log_sink_writer_identity = module.gcp-sg-logexp-org-gcs-001.writer_identity
}

# Log folder Platform (gồm cả con) → hot log bucket
module "gcp-sg-logexp-fldr-platform-001" {
  source  = "terraform-google-modules/log-export/google"
  version = "10.0.0"

  log_sink_name        = "gcp-sg-logexp-fldr-platform-001"
  parent_resource_type = "folder"
  parent_resource_id   = local.org.folder_id_platform
  include_children     = true
  destination_uri      = module.gcp-sg-logbkt-fldr-platform-001.destination_uri

  filter = <<-EOT
    log_id("cloudaudit.googleapis.com/activity")
    OR log_id("cloudaudit.googleapis.com/data_access")
    OR log_id("cloudaudit.googleapis.com/system_event")
    OR log_id("cloudaudit.googleapis.com/policy")
    OR (log_id("compute.googleapis.com/firewall") AND resource.type="gce_subnetwork")
    OR (log_id("compute.googleapis.com/vpc_flows") AND resource.type="gce_subnetwork")
    OR (log_id("syslog") AND resource.type="gce_instance")
  EOT
}

module "gcp-sg-logbkt-fldr-platform-001" {
  source  = "terraform-google-modules/log-export/google//modules/logbucket"
  version = "10.0.0"

  name                     = "gcp-sg-logbkt-fldr-platform-001"
  project_id               = local.central_logging_project
  location                 = local.log_region
  retention_days           = 90
  log_sink_writer_identity = module.gcp-sg-logexp-fldr-platform-001.writer_identity
}
