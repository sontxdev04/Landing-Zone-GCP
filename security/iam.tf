# User-level IAM bindings only.
# Service accounts and SA role grants are created manually via gcloud (see README §6.1).

locals {
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

  # Cartesian product: every role x every principal => one binding
  org_role_bindings = {
    for pair in setproduct(local.user_org_roles, var.admin_principals) :
    "${pair[0]}|${pair[1]}" => { role = pair[0], member = pair[1] }
  }
}

# Org-level admin roles for the configured principals (users or groups)
resource "google_organization_iam_member" "user_org_roles" {
  for_each = local.org_role_bindings
  org_id   = var.org_id
  role     = each.value.role
  member   = each.value.member
}

# Scoped log view reader for astronomy-shop (view created in management stack)
resource "google_project_iam_member" "gcp-sg-logview-astronomy-shop-reader-001" {
  for_each = toset(var.admin_principals)
  project  = local.org.project_id_management
  role     = "roles/logging.viewAccessor"
  member   = each.value

  condition {
    title       = "read-astronomy-shop-log-view-only"
    description = "Grants log view access scoped to the astronomy-shop log view"
    expression  = "resource.name == \"projects/${local.org.project_id_management}/locations/asia-southeast1/buckets/gcp-sg-logbkt-fldr-platform-001/views/gcp-sg-logview-astronomy-shop-001\""
  }
}
