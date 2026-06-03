# Shared naming source — reused by downstream stacks for globally-unique names
output "prefix" {
  description = "Prefix used for globally-unique resource names"
  value       = local.prefix
}

output "name_suffix" {
  description = "Random suffix appended to globally-unique resource names"
  value       = local.name_suffix
}

# Project IDs
output "project_id_hub_net" {
  description = "Project ID of the hub network project"
  value       = module.lz-prj-hub-net.project_id
}

output "project_id_sh_access" {
  description = "Project ID of the shared access project"
  value       = module.lz-prj-sh-access.project_id
}

output "project_id_sh_vpc" {
  description = "Project ID of the shared VPC host project"
  value       = module.lz-prj-sh-vpc.project_id
}

output "project_id_astronomy_shop" {
  description = "Project ID of the astronomy-shop workload project"
  value       = module.lz-prj-astronomy-shop.project_id
}

output "project_id_management" {
  description = "Project ID of the central observability/management project (logging + monitoring + audit archive)"
  value       = module.gcp-platform-management.project_id
}

# Folder IDs
output "folder_id_platform" {
  description = "Top-level platform folder ID (parent of connectivity/management)"
  value       = module.folders-root.ids["fldr-platform"]
}


