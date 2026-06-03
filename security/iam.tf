# Data sources — project references

data "google_project" "gcp-sg-prj-hub-net-001" {
  project_id = local.org.project_id_hub_net
}

data "google_project" "gcp-sg-prj-sh-access-001" {
  project_id = local.org.project_id_sh_access
}

data "google_project" "gcp-sg-prj-sh-vpc-001" {
  project_id = local.org.project_id_sh_vpc
}

data "google_project" "gcp-sg-prj-astronomy-shop-001" {
  project_id = local.org.project_id_astronomy_shop
}

locals {
  sa_hub_net_roles = [
    "roles/compute.networkAdmin",
    "roles/dns.admin",
  ]

  sa_sh_vpc_roles = [
    "roles/compute.networkAdmin",
  ]

  sa_sh_access_roles = [
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
  ]

  sa_astronomy_shop_roles = [
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
  ]

  user_org_roles = [
    "roles/resourcemanager.organizationAdmin",
    "roles/billing.user",
    "roles/resourcemanager.projectCreator",
    "roles/resourcemanager.folderAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/compute.osLogin",
    "roles/monitoring.viewer",
    "roles/logging.privateLogViewer",
  ]
}

# Service Account: hub-net
resource "google_service_account" "sa-hub-net" {
  account_id   = "gcp-sg-sa-hub-net-001"
  display_name = "gcp-sg-sa-hub-net-001"
  description  = "SA for hub network management (VPC, routing, firewall)"
  project      = data.google_project.gcp-sg-prj-hub-net-001.project_id
}

resource "google_project_iam_member" "sa-hub-net-roles" {
  for_each = toset(local.sa_hub_net_roles)
  project  = data.google_project.gcp-sg-prj-hub-net-001.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa-hub-net.email}"
}

# Service Account: sh-vpc
resource "google_service_account" "sa-sh-vpc" {
  account_id   = "gcp-sg-sa-sh-vpc-001"
  display_name = "gcp-sg-sa-sh-vpc-001"
  description  = "SA for Shared VPC prod host project management"
  project      = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
}

resource "google_project_iam_member" "sa-sh-vpc-roles" {
  for_each = toset(local.sa_sh_vpc_roles)
  project  = data.google_project.gcp-sg-prj-sh-vpc-001.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa-sh-vpc.email}"
}

# Service Account: sh-access
resource "google_service_account" "sa-sh-access" {
  account_id   = "gcp-sg-sa-sh-access-001"
  display_name = "gcp-sg-sa-sh-access-001"
  description  = "SA for bastion host, IAP tunnel and OS Login"
  project      = data.google_project.gcp-sg-prj-sh-access-001.project_id
}

resource "google_project_iam_member" "sa-sh-access-roles" {
  for_each = toset(local.sa_sh_access_roles)
  project  = data.google_project.gcp-sg-prj-sh-access-001.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa-sh-access.email}"
}

# Service Account: astronomy-shop workload
resource "google_service_account" "sa-astronomy-shop" {
  account_id   = "gcp-sg-sa-astronomy-shop-001"
  display_name = "gcp-sg-sa-astronomy-shop-001"
  description  = "SA for deploying and operating the astronomy-shop workload"
  project      = data.google_project.gcp-sg-prj-astronomy-shop-001.project_id
}

resource "google_project_iam_member" "sa-astronomy-shop-roles" {
  for_each = toset(local.sa_astronomy_shop_roles)
  project  = data.google_project.gcp-sg-prj-astronomy-shop-001.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa-astronomy-shop.email}"
}

# User org-level roles
resource "google_organization_iam_member" "user_org_roles" {
  for_each = toset(local.user_org_roles)
  org_id   = var.org_id
  role     = each.value
  member   = "user:${var.user_email}"
}

# Shared VPC admin roles at org level
resource "google_organization_iam_member" "sa-hub-net-xpnAdmin" {
  org_id = var.org_id
  role   = "roles/compute.xpnAdmin"
  member = "serviceAccount:${google_service_account.sa-hub-net.email}"
}

# sa-sh-vpc does not need xpnAdmin — sa-hub-net already holds that role at org level

# Scoped log view reader for astronomy-shop (view created in management stack)
resource "google_project_iam_member" "gcp-sg-logview-astronomy-shop-reader-001" {
  project = local.org.project_id_management
  role    = "roles/logging.viewAccessor"
  member  = "user:${var.user_email}"

  condition {
    title       = "read-astronomy-shop-log-view-only"
    description = "Grants log view access scoped to the astronomy-shop log view"
    expression  = "resource.name == \"projects/${local.org.project_id_management}/locations/asia-southeast1/buckets/gcp-sg-logbkt-fldr-platform-001/views/gcp-sg-logview-astronomy-shop-001\""
  }
}
