# =============================================================================
# ORG · Cây thư mục (Folder Hierarchy)
# -----------------------------------------------------------------------------
# Mục đích : Tạo phân cấp folder dưới Organization để cô lập ranh giới và
#            ủy quyền quản trị theo nhóm chức năng. Apply stack này đầu tiên.
# =============================================================================

# Cấp 1: các folder cấp cao nhất nằm trực tiếp dưới Organization
module "folders-root" {
  source  = "terraform-google-modules/folders/google"
  version = "5.1.0"

  parent = "organizations/${var.org_id}"
  names = [
    "fldr-platform",
    "fldr-workload",
    "fldr-sandbox",
  ]
  deletion_protection = false
}

# Cấp 2: folder con của "platform" (hạ tầng dùng chung)
module "folders-platform" {
  source  = "terraform-google-modules/folders/google"
  version = "5.1.0"

  parent = module.folders-root.ids["fldr-platform"]
  names = [
    "fldr-management",
    "fldr-connectivity",
  ]
  deletion_protection = false
}
