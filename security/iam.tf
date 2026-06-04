# User-level IAM bindings only.
# Service accounts and SA role grants are created manually via gcloud (see README §6.1).

locals {
  # ── Org-level role bindings ──────────────────────────────────────────────────
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

  # Cartesian product: every role × every principal → one binding each
  org_role_bindings = {
    for pair in setproduct(local.user_org_roles, var.admin_principals) :
    "${pair[0]}|${pair[1]}" => { role = pair[0], member = pair[1] }
  }

  # ── Cloud IAP — SSH tunnel access (no bastion host required) ─────────────────
  # Usage: gcloud compute ssh <VM> --project <PROJECT> --zone asia-southeast1-b --tunnel-through-iap
  iap_projects = [
    local.org.project_id_sample_app,
    local.org.project_id_hub_net,
    local.org.project_id_sh_vpc,
  ]

  # Cartesian product: every project × every principal → one binding each
  iap_bindings = {
    for pair in setproduct(local.iap_projects, var.admin_principals) :
    "${pair[0]}|${pair[1]}" => { project = pair[0], member = pair[1] }
  }
}

# Org-level admin roles for the configured principals (users or groups)
resource "google_organization_iam_member" "user_org_roles" {
  for_each = local.org_role_bindings
  org_id   = var.org_id
  role     = each.value.role
  member   = each.value.member
}

# Scoped log view reader — read-only access to the sample-app log view
resource "google_project_iam_member" "gcp-sg-logview-sample-app-reader-001" {
  for_each = toset(var.admin_principals)
  project  = local.org.project_id_management
  role     = "roles/logging.viewAccessor"
  member   = each.value

  condition {
    title       = "read-sample-app-log-view-only"
    description = "Grants log view access scoped to the sample-app log view"
    expression  = "resource.name == \"projects/${local.org.project_id_management}/locations/asia-southeast1/buckets/gcp-sg-logbkt-fldr-platform-001/views/gcp-sg-logview-sample-app-001\""
  }
}

# Grant IAP tunnel accessor — required for gcloud compute ssh --tunnel-through-iap
resource "google_project_iam_member" "gcp-sg-iap-tunnel-accessor-001" {
  for_each = local.iap_bindings
  project  = each.value.project
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value.member
}

# Grant OS Admin Login — required alongside OS Login to SSH as an admin user
resource "google_project_iam_member" "gcp-sg-os-admin-login-001" {
  for_each = local.iap_bindings
  project  = each.value.project
  role     = "roles/compute.osAdminLogin"
  member   = each.value.member
}
