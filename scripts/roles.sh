# shellcheck shell=bash
# =============================================================================
# roles.sh — BẢNG PHÂN QUYỀN (DỮ LIỆU). Đây là file DUY NHẤT bạn cần sửa khi
# muốn THÊM / BỚT role cho các Service Account. File này KHÔNG chứa logic —
# chỉ là các bảng dữ liệu. Logic chạy nằm ở lib.sh và các script 01/02/03.
#
# Quy ước: mỗi dòng là các cột cách nhau bằng khoảng trắng. Phần sau dấu '#'
# là chú thích (bị bỏ qua). Source SAU config.sh nên dùng được $SA_*, $GRP_*,
# $BILLING_ACCOUNT_*.  KHÔNG cần biết project_id thật (dùng PROJECT_KEY).
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# [1] Role cấp ORGANIZATION cho TF Runner SA        cột:  <SA>  <role>
#     → dùng ở 01-bootstrap.sh (Bước E)
#     (sa-tf-wl-001 không có role cấp org — role project-level ở bảng [6])
# ─────────────────────────────────────────────────────────────────────────────
ORG_ROLE_BINDINGS=(
  "$SA_ORG   roles/resourcemanager.organizationAdmin"   # tạo Folder/Project
  "$SA_ORG   roles/resourcemanager.folderCreator"       # resourcemanager.folders.create (organizationAdmin KHÔNG có)
  "$SA_ORG   roles/resourcemanager.projectCreator"
  "$SA_ORG   roles/serviceusage.serviceUsageAdmin"
  "$SA_ORG   roles/orgpolicy.policyAdmin"               # Org Policies
  "$SA_CONN  roles/compute.xpnAdmin"                     # Shared VPC
  "$SA_CONN  roles/compute.networkAdmin"                 # VPC/Subnet/Router/NAT/VPN (KHÔNG gồm firewall)
  "$SA_CONN  roles/compute.securityAdmin"                # Firewall rules (networkAdmin chỉ đọc được firewall)
  "$SA_CONN  roles/dns.admin"
  "$SA_SEC   roles/resourcemanager.organizationAdmin"   # Org IAM cho admin_principals
  "$SA_SEC   roles/compute.orgFirewallPolicyAdmin"       # tạo/sửa org firewall policy + rules
  "$SA_SEC   roles/compute.orgSecurityResourceAdmin"     # setFirewallPolicy → ASSOCIATE policy vào org
  "$SA_MGMT  roles/logging.admin"                        # Log Sinks org+folder
)

# [2] Role trên BILLING ACCOUNT       cột:  <billing account>  <SA>  <role>
BILLING_ROLE_BINDINGS=(
  "$BILLING_ACCOUNT_1  $SA_ORG  roles/billing.user"
  "$BILLING_ACCOUNT_2  $SA_ORG  roles/billing.user"
)

# [3] TOKEN CREATOR: team nào được impersonate SA nào   cột:  <SA>  <member>
TOKEN_CREATOR_BINDINGS=(
  "$SA_ORG   $GRP_FOUNDATION"
  "$SA_CONN  $GRP_NETWORK"
  "$SA_SEC   $GRP_SECURITY"
  "$SA_WL    $GRP_APP"
  "$SA_MGMT  $GRP_SRE"
)

# [4] STATE BUCKET — quyền GHI prefix của stack MÌNH    cột:  <SA>  <stack>
STATE_OWN_BINDINGS=(
  "$SA_ORG   org"
  "$SA_CONN  connectivity"
  "$SA_SEC   security"
  "$SA_WL    workload"
  "$SA_MGMT  management"
)

# [5] STATE BUCKET — quyền ĐỌC prefix UPSTREAM          cột:  <SA>  <upstream stack>
STATE_UPSTREAM_BINDINGS=(
  "$SA_CONN  org"           # connectivity → org
  "$SA_SEC   org"           # security     → org
  "$SA_WL    org"           # workload     → org + connectivity
  "$SA_WL    connectivity"
  "$SA_MGMT  org"           # management   → org + connectivity + workload
  "$SA_MGMT  connectivity"
  "$SA_MGMT  workload"
)

# ─────────────────────────────────────────────────────────────────────────────
# [6] Role cấp PROJECT (gán SAU apply org)   cột:  <PROJECT_KEY>  <SA>  <role>
#     → dùng ở 02-post-org-roles.sh (Bước J)
#     PROJECT_KEY ∈ MGMT | APP | HUB_NET | SH_VPC
# ─────────────────────────────────────────────────────────────────────────────
POSTORG_PROJECT_BINDINGS=(
  # J1: security đặt IAM cho log view trên project management.
  "MGMT     $SA_SEC   roles/resourcemanager.projectIamAdmin"

  # J2: workload tạo VM mẫu sample-app trên project app.
  "APP      $SA_WL    roles/compute.instanceAdmin.v1"
  # J2b: VM ở project app dùng SUBNET nằm ở project host sh-vpc (Shared VPC).
  #      Tạo instance cần 'compute.subnetworks.use' → nằm trong compute.networkUser
  #      trên PROJECT HOST. instanceAdmin.v1 trên app KHÔNG bao gồm quyền này.
  "SH_VPC   $SA_WL    roles/compute.networkUser"

  # J3: management quản lý Log Sinks/Buckets/Views, Monitoring, GCS trên project management.
  "MGMT     $SA_MGMT  roles/logging.admin"
  "MGMT     $SA_MGMT  roles/monitoring.admin"
  "MGMT     $SA_MGMT  roles/storage.admin"
  "MGMT     $SA_MGMT  roles/resourcemanager.projectIamAdmin"   # bucketWriter cho sink

  # J4: serviceUsageConsumer trên billing_project của mỗi stack hạ nguồn.
  #     Các stack đặt user_project_override=true + billing_project=<project>,
  #     nên SA của stack cần quyền 'serviceusage.services.use' trên project đó
  #     (không nằm trong networkAdmin/instanceAdmin/storage.admin/...).
  "HUB_NET  $SA_CONN  roles/serviceusage.serviceUsageConsumer"  # connectivity → hub-net
  "APP      $SA_WL    roles/serviceusage.serviceUsageConsumer"  # workload      → sample-app
  "MGMT     $SA_MGMT  roles/serviceusage.serviceUsageConsumer"  # management    → management
  "MGMT     $SA_SEC   roles/serviceusage.serviceUsageConsumer"  # security      → management

  # J5: security gắn IAP/OS-login binding (google_project_iam_member) lên 3 project
  #     app/hub-net/sh-vpc → cần projectIamAdmin trên cả 3 (ngoài MGMT đã có ở J1).
  "APP      $SA_SEC   roles/resourcemanager.projectIamAdmin"
  "HUB_NET  $SA_SEC   roles/resourcemanager.projectIamAdmin"
  "SH_VPC   $SA_SEC   roles/resourcemanager.projectIamAdmin"

  # J6: management gom app/hub-net/sh-vpc vào metric scope của project management
  #     (google_monitoring_monitored_project). Quyền monitoring.metricsScopes.link
  #     phải có trên CẢ scoping project (MGMT, đã có ở J3) LẪN từng project bị thêm.
  "APP      $SA_MGMT  roles/monitoring.admin"
  "HUB_NET  $SA_MGMT  roles/monitoring.admin"
  "SH_VPC   $SA_MGMT  roles/monitoring.admin"
)

# [7] Role BILLING (gán SAU apply org)      cột:  <billing account>  <SA>  <role>
POSTORG_BILLING_BINDINGS=(
  "$BILLING_ACCOUNT_BUDGET  $SA_MGMT  roles/billing.costsManager"
)

# ─────────────────────────────────────────────────────────────────────────────
# [8] RUNTIME SA cho VM/workload (Phase B)   → dùng ở 03-runtime-sa.sh
#     cột:  <nhóm>  <account_id>  <PROJECT_KEY>  <actAs>  |  <display name>
#       nhóm  ∈ core (luôn tạo) | app (cần cờ --app) | tools (cần cờ --tools)
#       actAs ∈ yes (cấp sa-tf-wl-001 quyền actAs SA này) | no
#     Role gán cố định cho mọi runtime SA: xem RUNTIME_FIXED_ROLES bên dưới.
# ─────────────────────────────────────────────────────────────────────────────
RUNTIME_SA_BINDINGS=(
  "app    gcp-sg-sa-sample-app-001  APP      yes  | Sample-app workload runtime SA"
  "tools  gcp-sg-sa-hub-net-001     HUB_NET  no   | hub-net runtime SA"
  "tools  gcp-sg-sa-sh-vpc-001      SH_VPC   no   | sh-vpc runtime SA"
)
RUNTIME_FIXED_ROLES=(
  roles/monitoring.metricWriter
  roles/logging.logWriter
)
