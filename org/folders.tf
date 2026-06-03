# Folder hierarchy (terraform-google-modules/folders) — apply this stack first

# Level 1: top-level folders under the organization
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

# Level 2: subfolders of "platform" (shared infrastructure) — aligned with VIB layout
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
