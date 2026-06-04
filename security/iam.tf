# =============================================================================
# SECURITY · IAM cấp người dùng & truy cập Cloud IAP
# -----------------------------------------------------------------------------
# Mục đích : Chỉ gán IAM cho principal con người (user/group). Service Account
#            và quyền cho SA được tạo thủ công qua gcloud (xem README §6.1).
# =============================================================================

locals {
  # ── Các role cấp Org gán cho principal con người ──────────────────────
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

  # Tích Descartes: mỗi role × mỗi principal → một binding
  org_role_bindings = {
    for pair in setproduct(local.user_org_roles, var.admin_principals) :
    "${pair[0]}|${pair[1]}" => { role = pair[0], member = pair[1] }
  }

  # ── Cloud IAP — truy cập SSH qua tunnel (không cần bastion host) ──────────
  # Cách dùng: gcloud compute ssh <VM> --project <PROJECT> --zone asia-southeast1-b --tunnel-through-iap
  iap_projects = [
    local.org.project_id_sample_app,
    local.org.project_id_hub_net,
    local.org.project_id_sh_vpc,
  ]

  # Tích Descartes: mỗi project × mỗi principal → một binding
  iap_bindings = {
    for pair in setproduct(local.iap_projects, var.admin_principals) :
    "${pair[0]}|${pair[1]}" => { project = pair[0], member = pair[1] }
  }
}

# Role admin cấp Org cho các principal đã cấu hình (user hoặc group)
resource "google_organization_iam_member" "user_org_roles" {
  for_each = local.org_role_bindings
  org_id   = var.org_id
  role     = each.value.role
  member   = each.value.member
}

# Quyền đọc Log View đóng khung — chỉ đọc log view của sample-app
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

# Cấp IAP tunnel accessor — cần cho gcloud compute ssh --tunnel-through-iap
resource "google_project_iam_member" "gcp-sg-iap-tunnel-accessor-001" {
  for_each = local.iap_bindings
  project  = each.value.project
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value.member
}

# Cấp OS Admin Login — cần kèm OS Login để SSH với quyền admin
resource "google_project_iam_member" "gcp-sg-os-admin-login-001" {
  for_each = local.iap_bindings
  project  = each.value.project
  role     = "roles/compute.osAdminLogin"
  member   = each.value.member
}
