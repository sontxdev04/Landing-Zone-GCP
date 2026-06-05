#!/usr/bin/env bash
# =============================================================================
# 03-runtime-sa.sh — Phase B: tạo Runtime Service Account cho VM / Workload.
#
# Mục đích : Các SA này KHÔNG dùng để chạy Terraform mà được GẮN vào VM/workload
#            lúc runtime (vd: ghi log/metric). Tách bạch với 5 TF Runner SA.
# Yêu cầu  : Đã `terraform apply` xong stack `org` (project_id thật sinh từ
#            random_string chỉ có sau khi apply). Chạy từ thư mục gốc landing-zone.
# Idempotent: Tạo lại an toàn — SA đã tồn tại sẽ bỏ qua, các binding chạy lặp được.
#
# Cách dùng:
#   ./scripts/03-runtime-sa.sh --app            # SA cho sample-app
#   ./scripts/03-runtime-sa.sh --tools          # SA cho hub-net / sh-vpc tools
#   ./scripts/03-runtime-sa.sh --app --tools    # cả hai nhóm
#   (nhóm "core" — nếu có — luôn được tạo, không cần cờ)
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

DO_APP=0
DO_TOOLS=0
for arg in "$@"; do
  case "$arg" in
    --app) DO_APP=1 ;;
    --tools) DO_TOOLS=1 ;;
    *) echo "Tham số không hợp lệ: $arg (chỉ chấp nhận --app, --tools)"; exit 1 ;;
  esac
done

echo "==> Lấy project_id từ output của stack org"
pushd "${REPO_ROOT}/org" >/dev/null
PRJ_APP="$(terraform output -raw project_id_sample_app)"
PRJ_HUB_NET="$(terraform output -raw project_id_hub_net)"
PRJ_SH_VPC="$(terraform output -raw project_id_sh_vpc)"
popd >/dev/null
export PRJ_APP PRJ_HUB_NET PRJ_SH_VPC

# Duyệt bảng RUNTIME_SA_BINDINGS (trong roles.sh). Mỗi dòng tạo 1 SA +
# gán RUNTIME_FIXED_ROLES; nếu actAs=yes thì cấp sa-tf-wl-001 quyền actAs.
for entry in "${RUNTIME_SA_BINDINGS[@]}"; do
  meta="${entry%%|*}"                       # phần trước dấu '|'
  display="${entry#*|}"; display="${display# }"   # phần sau '|' = display name
  read -r grp acct key actas _ <<< "$meta"

  # Lọc theo nhóm + cờ dòng lệnh
  case "$grp" in
    core)  ;;                                        # luôn tạo, không cần cờ
    app)   [[ "$DO_APP" == "1" ]]   || continue ;;   # chỉ khi có --app
    tools) [[ "$DO_TOOLS" == "1" ]] || continue ;;   # chỉ khi có --tools
    *) echo "[ERROR] nhom khong hop le: $grp (roles.sh)"; exit 1 ;;
  esac

  prj="$(resolve_project "$key")"
  email="${acct}@${prj}.iam.gserviceaccount.com"
  echo "==> [$grp] $acct ($display) @ $prj"
  create_sa "$acct" "$prj" "$display"
  for role in "${RUNTIME_FIXED_ROLES[@]}"; do
    grant_project "$prj" "$email" "$role"
  done
  if [[ "$actas" == "yes" ]]; then
    # sa-tf-wl-001: actAs để Terraform GẮN SA này vào VM lúc tạo.
    grant_on_sa "$email" "$prj" "serviceAccount:$SA_WL" "roles/iam.serviceAccountUser" "$SA_ORG"
    # GRP_APP (nhóm người vận hành workload): actAs để SSH (OS Login) vào VM chạy
    # bằng SA này — GCP yêu cầu actAs trên SA của VM mới cho phép đăng nhập OS Login.
    grant_on_sa "$email" "$prj" "$GRP_APP" "roles/iam.serviceAccountUser" "$SA_ORG"
  fi
done

echo ""
echo "==> Phase B hoan tat."
