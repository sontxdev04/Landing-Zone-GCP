# Projects — prefix + random suffix ensures globally unique IDs across stacks
resource "random_string" "name_suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  name_suffix = random_string.name_suffix.result

  prefix = "lz"

  project_id_hub_net    = "${local.prefix}-prj-hub-net-${local.name_suffix}"
  project_id_sh_vpc     = "${local.prefix}-prj-sh-vpc-${local.name_suffix}"
  project_id_sample_app = "${local.prefix}-prj-sample-app-${local.name_suffix}"

  network_labels = {
    managed_by  = "terraform"
    environment = "prod"
    stack       = "connectivity"
  }
  infra_labels = {
    managed_by  = "terraform"
    environment = "prod"
    stack       = "landing-zone"
  }
}

# Hub network project (Connectivity)
resource "time_static" "lz-prj-hub-net-timestamp" {}

module "lz-prj-hub-net" {
  source  = "terraform-google-modules/project-factory/google"
  version = "17.1.0"

  name              = local.project_id_hub_net
  random_project_id = false
  org_id            = var.org_id
  billing_account   = var.billing_account_id_2
  folder_id         = module.folders-platform.ids["fldr-connectivity"]

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "orgpolicy.googleapis.com",
    "dns.googleapis.com",
  ]

  labels = merge(
    local.network_labels,
    { created_date = formatdate("YYYY-MM-DD_hh-mm-ss", timeadd(time_static.lz-prj-hub-net-timestamp.rfc3339, "7h")) }
  )
  deletion_policy = "DELETE"
}

# Shared VPC prod host project (Connectivity)
resource "time_static" "lz-prj-sh-vpc-timestamp" {}

module "lz-prj-sh-vpc" {
  source  = "terraform-google-modules/project-factory/google"
  version = "17.1.0"

  name              = local.project_id_sh_vpc
  random_project_id = false
  org_id            = var.org_id
  billing_account   = var.billing_account_id_2
  folder_id         = module.folders-platform.ids["fldr-connectivity"]

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]

  labels = merge(
    local.network_labels,
    { created_date = formatdate("YYYY-MM-DD_hh-mm-ss", timeadd(time_static.lz-prj-sh-vpc-timestamp.rfc3339, "7h")) }
  )
  deletion_policy = "DELETE"
}


# Sample-app workload service project (Workload folder)
resource "time_static" "lz-prj-sample-app-timestamp" {}

module "lz-prj-sample-app" {
  source  = "terraform-google-modules/project-factory/google"
  version = "17.1.0"

  name              = local.project_id_sample_app
  random_project_id = false
  org_id            = var.org_id
  billing_account   = var.billing_account_id_2
  folder_id         = module.folders-root.ids["fldr-workload"]

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]

  labels = merge(
    local.infra_labels,
    { created_date = formatdate("YYYY-MM-DD_hh-mm-ss", timeadd(time_static.lz-prj-sample-app-timestamp.rfc3339, "7h")) }
  )
  deletion_policy = "DELETE"
}

# Central management project: logging, monitoring, and audit archive
resource "time_static" "gcp-platform-management-timestamp" {}

module "gcp-platform-management" {
  source  = "terraform-google-modules/project-factory/google"
  version = "17.1.0"

  name              = "gcp-platform-management"
  random_project_id = true
  org_id            = var.org_id
  billing_account   = var.billing_account_id_1
  folder_id         = module.folders-platform.ids["fldr-management"]

  activate_apis = [
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "bigquery.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
  ]

  labels = merge(
    local.infra_labels,
    { created_date = formatdate("YYYY-MM-DD_hh-mm-ss", timeadd(time_static.gcp-platform-management-timestamp.rfc3339, "7h")) }
  )
  deletion_policy = "DELETE"
}

# Security tooling project: KMS, Secret Manager, Security Command Center (Platform / management)
resource "time_static" "gcp-platform-security-timestamp" {}

module "gcp-platform-security" {
  source  = "terraform-google-modules/project-factory/google"
  version = "17.1.0"

  name              = "gcp-platform-security"
  random_project_id = true
  org_id            = var.org_id
  billing_account   = var.billing_account_id_1
  folder_id         = module.folders-platform.ids["fldr-management"]

  activate_apis = [
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "securitycenter.googleapis.com",
    "pubsub.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ]

  labels = merge(
    local.infra_labels,
    { created_date = formatdate("YYYY-MM-DD_hh-mm-ss", timeadd(time_static.gcp-platform-security-timestamp.rfc3339, "7h")) }
  )
  deletion_policy = "DELETE"
}
