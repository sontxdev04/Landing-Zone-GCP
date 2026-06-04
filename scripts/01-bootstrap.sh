#!/usr/bin/env bash
# =============================================================================
# 01-bootstrap.sh — Phase A (Bước B → G): tạo Seed Project, State Bucket,
# 5 TF Runner SA, gán role tối thiểu, Token Creator cho team, cô lập GCS state.
#
# Chạy MỘT LẦN duy nhất, bằng tài khoản cá nhân có quyền Organization Admin.
# Trước khi chạy: đã `gcloud auth login` và `gcloud auth application-default login`.
#
#   ./scripts/01-bootstrap.sh
#
# An toàn chạy lại (idempotent): các lệnh add-iam-policy-binding và bucket
# versioning có thể chạy lặp; tạo project/SA/bucket đã tồn tại sẽ báo lỗi nhẹ.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
# shellcheck source=roles.sh
source "${SCRIPT_DIR}/roles.sh"
_lz_check_placeholders || exit 1

echo "==> Bước B: Tạo Seed Project & bật API"
gcloud projects create "$SEED_PROJECT" \
    --organization="$ORG_ID" --name="GCP Platform Bootstrap" || true
gcloud billing projects link "$SEED_PROJECT" --billing-account="$BILLING_ACCOUNT_1"
gcloud services enable \
    storage.googleapis.com \
    iam.googleapis.com \
    iamcredentials.googleapis.com \
    cloudresourcemanager.googleapis.com \
    cloudbilling.googleapis.com \
    serviceusage.googleapis.com \
    --project="$SEED_PROJECT"
gcloud auth application-default set-quota-project "$SEED_PROJECT"

echo "==> Bước C: Tạo GCS State Bucket với Object Versioning"
gcloud storage buckets create "gs://$STATE_BUCKET" \
    --project="$SEED_PROJECT" \
    --location="$REGION" \
    --uniform-bucket-level-access || true
gcloud storage buckets update "gs://$STATE_BUCKET" --versioning

echo "==> Bước D: Tạo 5 TF Runner SA"
create_sa sa-tf-org-001  "$SEED_PROJECT" "TF Runner for org stack"
create_sa sa-tf-conn-001 "$SEED_PROJECT" "TF Runner for connectivity stack"
create_sa sa-tf-sec-001  "$SEED_PROJECT" "TF Runner for security stack"
create_sa sa-tf-wl-001   "$SEED_PROJECT" "TF Runner for workload stack"
create_sa sa-tf-mgmt-001 "$SEED_PROJECT" "TF Runner for management stack"

echo "==> Bước E: Gán role TỐI THIỂU cho mỗi TF Runner SA"
# Danh sách role nằm trong roles.sh (bảng [1] và [2]). Muốn thêm role → sửa roles.sh.
apply_org_bindings
apply_billing_bindings "${BILLING_ROLE_BINDINGS[@]}"

echo "==> Bước F: Cấp Token Creator cho từng team trên SA của team mình"
apply_token_creator_bindings   # bảng [3] trong roles.sh

echo "==> Bước G: Cô lập GCS state theo prefix"
# G1. Tất cả 5 SA cần "thấy" được bucket để terraform init nhận diện backend
for sa in "$SA_ORG" "$SA_CONN" "$SA_SEC" "$SA_WL" "$SA_MGMT"; do
  grant_bucket_reader "$sa"
done
# G2. objectAdmin trên prefix stack MÌNH | G3. objectViewer trên prefix UPSTREAM
apply_state_bindings "roles/storage.objectAdmin"  own-state      "${STATE_OWN_BINDINGS[@]}"
apply_state_bindings "roles/storage.objectViewer" read-upstream  "${STATE_UPSTREAM_BINDINGS[@]}"

echo ""
echo "==> Phase A (Buoc B->G) hoan tat."
echo "   Tiếp theo (thủ công):"
echo "   - Bước H: sửa 5 tệp backend.tf → bucket = \"$STATE_BUCKET\""
echo "   - Bước I: kiểm tra tf_runner_sa trong 5 tệp terraform.tfvars"
echo "   - Chạy: cd org && terraform init && terraform apply"
echo "   - Sau đó: ./scripts/02-post-org-roles.sh"
