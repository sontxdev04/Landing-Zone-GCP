# =============================================================================
# ORG · Outputs — dữ liệu liên-stack
# -----------------------------------------------------------------------------
# Mục đích : Xuất prefix/suffix đặt tên, project ID và folder ID để các stack
#            hạ nguồn tiêu thụ qua terraform_remote_state.
# =============================================================================

# Nguồn đặt tên dùng chung — các stack hạ nguồn tái sử dụng để sinh tên duy nhất toàn cầu
output "prefix" {
  description = "Prefix dùng cho tên tài nguyên duy nhất toàn cầu"
  value       = local.prefix
}

output "name_suffix" {
  description = "Hậu tố ngẫu nhiên gắn vào tên tài nguyên duy nhất toàn cầu"
  value       = local.name_suffix
}

# ID các project
output "project_id_hub_net" {
  description = "Project ID của hub network project"
  value       = module.lz-prj-hub-net.project_id
}


output "project_id_sh_vpc" {
  description = "Project ID của Shared VPC host project"
  value       = module.lz-prj-sh-vpc.project_id
}

output "project_id_sample_app" {
  description = "Project ID của sample-app workload project"
  value       = module.lz-prj-sample-app.project_id
}

output "project_id_management" {
  description = "Project ID của project quản lý/quan sát trung tâm (logging + monitoring + audit archive)"
  value       = module.gcp-platform-management.project_id
}

# ID các folder
output "folder_id_platform" {
  description = "ID folder platform cấp cao nhất (cha của connectivity/management)"
  value       = module.folders-root.ids["fldr-platform"]
}

output "folder_id_workload" {
  description = "ID folder workload cấp cao nhất"
  value       = module.folders-root.ids["fldr-workload"]
}

output "folder_id_sandbox" {
  description = "ID folder sandbox cấp cao nhất"
  value       = module.folders-root.ids["fldr-sandbox"]
}

output "folder_id_management" {
  description = "ID folder con management (con của platform)"
  value       = module.folders-platform.ids["fldr-management"]
}

output "folder_id_connectivity" {
  description = "ID folder con connectivity (con của platform)"
  value       = module.folders-platform.ids["fldr-connectivity"]
}
