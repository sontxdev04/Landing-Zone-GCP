#!/usr/bin/env bash
# =============================================================================
# 02-post-org-roles.sh — Phase A Bước J: hoàn tất role project-level.
#
# Mục đích : Gán các role cấp project cho sa-tf-sec / sa-tf-wl / sa-tf-mgmt
#            (những quyền chỉ có thể cấp sau khi project đã tồn tại).
# Yêu cầu  : Đã `terraform apply` xong stack `org` (project_id thật sinh từ
#            random_string chỉ có sau khi apply). Chạy từ thư mục gốc landing-zone.
# Idempotent: Toàn bộ binding chạy lặp được; tự impersonate sa-tf-org-001 vì
#            project do SA này sở hữu (admin cá nhân không có setIamPolicy).
#
# Cách dùng:
#   ./scripts/02-post-org-roles.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
# shellcheck source=roles.sh
source "${SCRIPT_DIR}/roles.sh"
_lz_check_placeholders || exit 1

echo "==> Lấy project_id thật từ output của stack org"
pushd "${REPO_ROOT}/org" >/dev/null
PRJ_MGMT="$(terraform output -raw project_id_management)"
PRJ_APP="$(terraform output -raw project_id_sample_app)"
PRJ_HUB_NET="$(terraform output -raw project_id_hub_net)"
PRJ_SH_VPC="$(terraform output -raw project_id_sh_vpc)"
popd >/dev/null
export PRJ_MGMT PRJ_APP PRJ_HUB_NET PRJ_SH_VPC
echo "    PRJ_MGMT=$PRJ_MGMT  PRJ_APP=$PRJ_APP  PRJ_HUB_NET=$PRJ_HUB_NET  PRJ_SH_VPC=$PRJ_SH_VPC"

echo "==> Bước J: gán role project-level + billing (danh sách trong roles.sh bảng [6]/[7])"
apply_project_bindings "${POSTORG_PROJECT_BINDINGS[@]}"
apply_billing_bindings "${POSTORG_BILLING_BINDINGS[@]}"

echo ""
echo "==> Buoc J hoan tat. Co the tiep tuc apply cac stack con lai."
echo "   Nếu cần runtime SA cho VM/workload, chạy: ./scripts/03-runtime-sa.sh"
