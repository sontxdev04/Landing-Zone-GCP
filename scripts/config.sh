# shellcheck shell=bash
# =============================================================================
# config.sh — Biến cấu hình dùng chung cho toàn bộ script setup.
# KHÔNG chạy trực tiếp file này. Các script khác sẽ `source` nó.
# Hãy điều chỉnh các giá trị <...> bên dưới theo môi trường thực tế của bạn.
# =============================================================================

# --- Bắt buộc điều chỉnh ----------------------------------------------------
export ORG_ID="<ORG_ID>"                              # gcloud organizations list
export BILLING_ACCOUNT_1="<BILLING_ACCOUNT_ID_1>"     # Platform & Security
export BILLING_ACCOUNT_2="<BILLING_ACCOUNT_ID_2>"     # Networking & Workload
export BILLING_ACCOUNT_BUDGET="<BILLING_ACCOUNT_ID>"  # Budget của management stack (thường = $BILLING_ACCOUNT_1)
export STATE_BUCKET="gcp-sg-tfstate-<UNIQUE_SUFFIX>"  # Bắt buộc duy nhất toàn cầu

# --- Map team/group nhận quyền Token Creator trên TF Runner SA của team mình -
export GRP_FOUNDATION="group:grp-gcp-foundation@company.com"   # impersonate sa-tf-org-001
export GRP_NETWORK="group:grp-gcp-network@company.com"         # impersonate sa-tf-conn-001
export GRP_SECURITY="group:grp-gcp-security@company.com"       # impersonate sa-tf-sec-001
export GRP_APP="group:grp-gcp-app-eng@company.com"             # impersonate sa-tf-wl-001
export GRP_SRE="group:grp-gcp-sre@company.com"                 # impersonate sa-tf-mgmt-001

# --- Giá trị mặc định (thường không cần sửa) --------------------------------
export SEED_PROJECT="gcp-platform-bootstrap-001"
export REGION="asia-southeast1"

# --- Email tiện dụng của 5 TF Runner SA (suy ra từ SEED_PROJECT) ------------
export SA_ORG="sa-tf-org-001@${SEED_PROJECT}.iam.gserviceaccount.com"
export SA_CONN="sa-tf-conn-001@${SEED_PROJECT}.iam.gserviceaccount.com"
export SA_SEC="sa-tf-sec-001@${SEED_PROJECT}.iam.gserviceaccount.com"
export SA_WL="sa-tf-wl-001@${SEED_PROJECT}.iam.gserviceaccount.com"
export SA_MGMT="sa-tf-mgmt-001@${SEED_PROJECT}.iam.gserviceaccount.com"

# --- Kiểm tra các placeholder chưa được thay ---------------------------------
_lz_check_placeholders() {
  local bad=0 v
  for v in ORG_ID BILLING_ACCOUNT_1 BILLING_ACCOUNT_2 BILLING_ACCOUNT_BUDGET STATE_BUCKET; do
    case "${!v}" in
      *"<"*">"*) echo "[ERROR] Bien $v con placeholder: '${!v}' — sua trong scripts/config.sh"; bad=1 ;;
    esac
  done
  return $bad
}
