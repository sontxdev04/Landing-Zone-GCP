#!/usr/bin/env bash
# =============================================================================
# 02-post-org-roles.sh — Phase A Bước J: hoàn tất role project-level cho
# sa-tf-sec / sa-tf-wl / sa-tf-mgmt.
#
# CHẠY SAU `terraform apply` của stack org (vì project_id thật sinh từ
# random_string mới có sau khi apply). Phải chạy từ thư mục gốc landing-zone.
#
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
PRJ_SH_ACCESS="$(terraform output -raw project_id_sh_access)"
PRJ_ASTRO="$(terraform output -raw project_id_astronomy_shop)"
popd >/dev/null
export PRJ_MGMT PRJ_SH_ACCESS PRJ_ASTRO
echo "    PRJ_MGMT=$PRJ_MGMT  PRJ_SH_ACCESS=$PRJ_SH_ACCESS  PRJ_ASTRO=$PRJ_ASTRO"

echo "==> Bước J: gán role project-level + billing (danh sách trong roles.sh bảng [6]/[7])"
apply_project_bindings "${POSTORG_PROJECT_BINDINGS[@]}"
apply_billing_bindings "${POSTORG_BILLING_BINDINGS[@]}"

echo ""
echo "✅ Bước J hoàn tất. Có thể tiếp tục apply các stack còn lại."
echo "   Nếu cần runtime SA cho VM/workload, chạy: ./scripts/03-runtime-sa.sh"
