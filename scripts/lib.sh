# shellcheck shell=bash
# =============================================================================
# lib.sh — Hàm trợ giúp dùng chung cho các script setup.
# KHÔNG chạy trực tiếp. Source SAU config.sh:
#     source "${SCRIPT_DIR}/config.sh"
#     source "${SCRIPT_DIR}/lib.sh"
#
# Mục tiêu: gói lệnh gcloud dài thành hàm ngắn, để THÊM ROLE chỉ cần thêm
# 1 dòng vào bảng dữ liệu trong các script gọi (không phải copy-paste lệnh dài).
# =============================================================================

# Gán role cấp Organization cho 1 service account.
grant_org() { # $1=SA email  $2=role
  gcloud organizations add-iam-policy-binding "$ORG_ID" \
    --member="serviceAccount:$1" --role="$2" --condition=None
}

# Gán role cấp Project cho 1 service account.
grant_project() { # $1=project id  $2=SA email  $3=role
  gcloud projects add-iam-policy-binding "$1" \
    --member="serviceAccount:$2" --role="$3" --condition=None
}

# Gán role trên Billing Account.
grant_billing() { # $1=billing account  $2=SA email  $3=role
  gcloud billing accounts add-iam-policy-binding "$1" \
    --member="serviceAccount:$2" --role="$3"
}

# Gán role TRÊN chính một service account (impersonation: tokenCreator / serviceAccountUser).
grant_on_sa() { # $1=SA mục tiêu  $2=project của SA  $3=member  $4=role
  gcloud iam service-accounts add-iam-policy-binding "$1" \
    --project="$2" --member="$3" --role="$4"
}

# Cho SA "thấy" được state bucket (cần cho terraform init).
grant_bucket_reader() { # $1=SA email
  gcloud storage buckets add-iam-policy-binding "gs://$STATE_BUCKET" \
    --member="serviceAccount:$1" --role="roles/storage.legacyBucketReader" --condition=None
}

# Gán quyền trên state bucket GIỚI HẠN theo prefix terraform/<stack>/ (IAM Condition).
grant_state() { # $1=SA email  $2=role  $3=stack prefix  $4=title điều kiện
  gcloud storage buckets add-iam-policy-binding "gs://$STATE_BUCKET" \
    --member="serviceAccount:$1" --role="$2" \
    --condition="expression=resource.name.startsWith(\"projects/_/buckets/${STATE_BUCKET}/objects/terraform/$3/\"),title=$4"
}

# Tạo service account (idempotent — bỏ qua nếu đã tồn tại, không in ERROR rác).
# Sau khi tạo, CHỜ SA lan truyền (eventual consistency) trước khi trả về, để
# lệnh add-iam-policy-binding ngay sau đó không gặp lỗi "does not exist".
create_sa() { # $1=account id  $2=project  $3=display name
  local _email="$1@$2.iam.gserviceaccount.com"
  if gcloud iam service-accounts describe "$_email" --project="$2" >/dev/null 2>&1; then
    echo "    SA '$_email' da ton tai — bo qua."
    return 0
  fi
  gcloud iam service-accounts create "$1" --project="$2" --display-name="$3"
  # Poll cho tới khi SA hien dien (toi da ~60s) truoc khi gan role.
  local _i
  for _i in $(seq 1 12); do
    if gcloud iam service-accounts describe "$_email" --project="$2" >/dev/null 2>&1; then
      return 0
    fi
    echo "    Cho SA '$_email' san sang... ($_i/12)"
    sleep 5
  done
  echo "[WARNING] SA '$_email' tao xong nhung chua thay sau 60s — van tiep tuc." >&2
}

# Map PROJECT_KEY (trong roles.sh) → project_id thật.
# Các biến PRJ_* do script runner set TRƯỚC khi gọi (từ terraform output).
resolve_project() { # $1=PROJECT_KEY
  case "$1" in
    MGMT)    echo "$PRJ_MGMT" ;;
    APP)   echo "$PRJ_APP" ;;
    HUB_NET) echo "$PRJ_HUB_NET" ;;
    SH_VPC)  echo "$PRJ_SH_VPC" ;;
    *) echo "[ERROR] PROJECT_KEY khong hop le: '$1' (roles.sh)" >&2; return 1 ;;
  esac
}

# ── Áp dụng các BẢNG dữ liệu từ roles.sh (tách vòng lặp ra khỏi runner) ──────

apply_org_bindings() { # dùng mảng ORG_ROLE_BINDINGS
  local b sa role
  for b in "${ORG_ROLE_BINDINGS[@]}"; do
    read -r sa role _ <<< "$b"; grant_org "$sa" "$role"
  done
}

apply_billing_bindings() { # $@ = các dòng "<billing> <SA> <role>"
  local b acct sa role
  for b in "$@"; do
    read -r acct sa role _ <<< "$b"; grant_billing "$acct" "$sa" "$role"
  done
}

apply_token_creator_bindings() { # dùng mảng TOKEN_CREATOR_BINDINGS
  local b sa member
  for b in "${TOKEN_CREATOR_BINDINGS[@]}"; do
    read -r sa member _ <<< "$b"
    grant_on_sa "$sa" "$SEED_PROJECT" "$member" "roles/iam.serviceAccountTokenCreator"
  done
}

apply_state_bindings() { # $1=role  $2=title prefix  $3..=các dòng "<SA> <stack>"
  local role="$1" title="$2"; shift 2
  local b sa stack
  for b in "$@"; do
    read -r sa stack _ <<< "$b"; grant_state "$sa" "$role" "$stack" "${title}-${stack}"
  done
}

apply_project_bindings() { # $@ = các dòng "<PROJECT_KEY> <SA> <role>"
  local b key sa role
  for b in "$@"; do
    read -r key sa role _ <<< "$b"
    grant_project "$(resolve_project "$key")" "$sa" "$role"
  done
}
