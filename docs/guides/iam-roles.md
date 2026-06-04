<div align="center">

# 🔑 IAM & Mô hình Danh tính

### *Thiết kế danh tính, cơ chế Impersonation không key tĩnh và cô lập State file*

<br>

🔐 **Zero-Key Impersonation** &nbsp;•&nbsp; 👥 **5 Runner SA tách biệt** &nbsp;•&nbsp; 🧱 **State Isolation theo prefix**

</div>

---

## � Mục lục

- [💡 Triết lý thiết kế](#-triết-lý-thiết-kế)
- [🛡️ Mô hình IaC không key tĩnh (Zero-Key)](#️-mô-hình-iac-không-key-tĩnh-zero-key)
- [🏗️ 5 Terraform Runner Service Account](#️-5-terraform-runner-service-account)
- [👥 Ai được Impersonate SA nào?](#-ai-được-impersonate-sa-nào)
- [📜 Bảng phân quyền chi tiết](#-bảng-phân-quyền-chi-tiết)
- [🔒 Cô lập State file qua IAM Conditions](#-cô-lập-state-file-qua-iam-conditions)
- [👤 Quyền cho Quản trị viên (Human Identity)](#-quyền-cho-quản-trị-viên-human-identity)
- [🤖 Runtime SA cho Workload](#-runtime-sa-cho-workload)
- [⚙️ Quản lý phân quyền ở đâu?](#️-quản-lý-phân-quyền-ở-đâu)

---

## 💡 Triết lý thiết kế

Mô hình IAM của Landing Zone được xây dựng quanh ba nguyên tắc cốt lõi:

| Nguyên tắc | Ý nghĩa thực tiễn |
|:-----------|:------------------|
| 🚫 **Zero Static Key** | Không có bất kỳ file SA Key JSON nào được ghi ra đĩa, lưu trong repo hay máy cá nhân. |
| 🎭 **Impersonation** | Con người đăng nhập bằng danh tính cá nhân, rồi *mượn quyền* (impersonate) Service Account để chạy Terraform. |
| 🧩 **Separation of Duties** | Mỗi stack có một Runner SA riêng, chỉ chạm được đúng phạm vi của mình — cô lập bán kính ảnh hưởng (blast radius). |

---

## 🛡️ Mô hình IaC không key tĩnh (Zero-Key)

Để tuân thủ các khung bảo mật hiện đại (CIS Benchmarks, Google Cloud Architecture Framework), toàn bộ landing zone vận hành theo **chính sách không key tĩnh tuyệt đối**:

```mermaid
flowchart TD
    USER["👤 Danh tính cá nhân<br/>(Admin / Engineer)"]
    STORE["🔐 gcloud Credential Store"]
    SA["🤖 TF Runner Service Account"]
    TOKEN["⏱️ Short-Lived Token<br/>(token tạm, tự hết hạn)"]
    TF["⚙️ Terraform Apply"]

    USER -->|"gcloud auth login"| STORE
    STORE -->|"Impersonate<br/>(serviceAccountTokenCreator)"| SA
    SA --> TOKEN
    TOKEN --> TF

    classDef u fill:#e8f0fe,stroke:#1a73e8,color:#174ea6;
    classDef s fill:#fce8e6,stroke:#d93025,color:#a50e0e;
    class USER,STORE u;
    class SA,TOKEN,TF s;
```

| Đặc tính | Mô tả |
|:---------|:------|
| 🚫 **Không key tĩnh** | Không có JSON credential nào trong repo, workspace hay máy local. |
| 🎭 **SA Impersonation** | Provider Terraform tự động mượn quyền SA đích nhờ `roles/iam.serviceAccountTokenCreator`. |
| 🔍 **Audit Trail kép** | Mỗi hành động trong Cloud Audit Log gắn với *cả* Service Account *lẫn* danh tính người đã khởi tạo phiên impersonation. |
| 🛡️ **Org Policy gia cố** | Chính sách `iam.disableServiceAccountKeyCreation` chặn tạo SA Key ngay từ gốc tổ chức. |

> [!TIP]
> Vì token là ngắn hạn và tự hết hạn, kể cả khi phiên làm việc bị lộ thì kẻ tấn công cũng không có credential dài hạn để tái sử dụng.

---

## 🏗️ 5 Terraform Runner Service Account

Hạ tầng được chia thành **5 lớp stack độc lập**. Mỗi lớp chạy dưới một Runner Service Account riêng, tất cả đều đặt trong **Seed Project** (`gcp-platform-bootstrap-001`):

| Service Account | Stack quản lý | Đội sở hữu | Phạm vi quyền chính |
|:----------------|:-------------:|:-----------|:--------------------|
| 🟣 **`sa-tf-org-001`** | [`org/`](../../org/) | Foundation Admins | **Org:** `organizationAdmin`, `folderCreator`, `projectCreator`, `serviceUsageAdmin`, `orgpolicy.policyAdmin` · **Billing:** `billing.user` (cả 2 account) |
| 🔵 **`sa-tf-conn-001`** | [`connectivity/`](../../connectivity/) | Network Ops | **Org:** `compute.xpnAdmin`, `compute.networkAdmin`, `compute.securityAdmin`, `dns.admin` · **Project:** `serviceUsageConsumer` (hub-net) |
| 🔴 **`sa-tf-sec-001`** | [`security/`](../../security/) | Security Ops | **Org:** `organizationAdmin`, `compute.orgFirewallPolicyAdmin`, `compute.orgSecurityResourceAdmin` · **Project:** `projectIamAdmin` (mgmt/app/hub-net/sh-vpc), `serviceUsageConsumer` (mgmt) |
| 🟢 **`sa-tf-wl-001`** | [`workload/`](../../workload/) | App Engineers | **Project:** `compute.instanceAdmin.v1` (sample-app), `compute.networkUser` (sh-vpc host), `serviceUsageConsumer` (sample-app) · `iam.serviceAccountUser` trên runtime SA |
| 🟡 **`sa-tf-mgmt-001`** | [`management/`](../../management/) | SRE Platform | **Org:** `logging.admin` · **Project (mgmt+app+hub-net+sh-vpc):** `monitoring.admin` · **Project (mgmt):** `logging.admin`, `storage.admin`, `projectIamAdmin`, `serviceUsageConsumer` · **Billing:** `billing.costsManager` |

---

## 👥 Ai được Impersonate SA nào?

Mỗi nhóm con người (Google Group) chỉ được cấp `serviceAccountTokenCreator` trên đúng Runner SA của đội mình — không ai có thể mượn quyền của stack khác.

```mermaid
flowchart LR
    F["👥 grp-gcp-foundation"] -->|Token Creator| SAO["🟣 sa-tf-org-001"]
    N["👥 grp-gcp-network"]    -->|Token Creator| SAC["🔵 sa-tf-conn-001"]
    S["👥 grp-gcp-security"]   -->|Token Creator| SAS["🔴 sa-tf-sec-001"]
    A["👥 grp-gcp-app-eng"]    -->|Token Creator| SAW["🟢 sa-tf-wl-001"]
    R["👥 grp-gcp-sre"]        -->|Token Creator| SAM["🟡 sa-tf-mgmt-001"]
```

| Google Group | Impersonate được | Stack |
|:-------------|:-----------------|:------|
| `grp-gcp-foundation` | `sa-tf-org-001` | org |
| `grp-gcp-network` | `sa-tf-conn-001` | connectivity |
| `grp-gcp-security` | `sa-tf-sec-001` | security |
| `grp-gcp-app-eng` | `sa-tf-wl-001` | workload |
| `grp-gcp-sre` | `sa-tf-mgmt-001` | management |

> [!NOTE]
> Ánh xạ Group ↔ SA được khai báo trong bảng `TOKEN_CREATOR_BINDINGS` tại [scripts/roles.sh](../../scripts/roles.sh); địa chỉ email các group được cấu hình trong [scripts/config.sh](../../scripts/config.sh).

---

## 📜 Bảng phân quyền chi tiết

Toàn bộ quyền được khai báo dưới dạng **dữ liệu thuần** trong [scripts/roles.sh](../../scripts/roles.sh) và gán qua 3 script setup theo thứ tự.

### 🟣 Cấp Organization — `[1] ORG_ROLE_BINDINGS`

| Service Account | Roles |
|:----------------|:------|
| `sa-tf-org-001` | `resourcemanager.organizationAdmin`, `resourcemanager.folderCreator`, `resourcemanager.projectCreator`, `serviceusage.serviceUsageAdmin`, `orgpolicy.policyAdmin` |
| `sa-tf-conn-001` | `compute.xpnAdmin`, `compute.networkAdmin`, `compute.securityAdmin`, `dns.admin` |
| `sa-tf-sec-001` | `resourcemanager.organizationAdmin`, `compute.orgFirewallPolicyAdmin`, `compute.orgSecurityResourceAdmin` |
| `sa-tf-mgmt-001` | `logging.admin` |

> 🟢 `sa-tf-wl-001` **không có** role cấp org — chỉ nhận quyền ở cấp project (xem bảng J).

> [!NOTE]
> Ba role dưới đây dễ bị bỏ sót vì chúng bổ sung quyền mà role "chính" KHÔNG bao gồm:
> - `folderCreator` — `organizationAdmin` **không** có `resourcemanager.folders.create`.
> - `compute.securityAdmin` — `networkAdmin` chỉ **đọc** được firewall; tạo/sửa firewall cần role này.
> - `compute.orgSecurityResourceAdmin` — `orgFirewallPolicyAdmin` chỉ tạo/sửa policy; **associate** policy vào Org cần role này.

### 💳 Cấp Billing — `[2] BILLING_ROLE_BINDINGS`

| Billing Account | Service Account | Role |
|:----------------|:----------------|:-----|
| Account #1 (Platform & Security) | `sa-tf-org-001` | `billing.user` |
| Account #2 (Networking & Workload) | `sa-tf-org-001` | `billing.user` |

### 📦 Cấp Project — `[6] POSTORG_PROJECT_BINDINGS` *(gán sau khi apply `org/`)*

Bảng này được chia thành 6 nhóm logic (J1–J6) — khớp từng nhóm trong [scripts/roles.sh](../../scripts/roles.sh):

| # | Project | Service Account | Role | Mục đích |
|:--|:--------|:----------------|:-----|:---------|
| J1 | `management` | `sa-tf-sec-001` | `resourcemanager.projectIamAdmin` | Set IAM cho Log View |
| J2 | `sample-app` | `sa-tf-wl-001` | `compute.instanceAdmin.v1` | Tạo VM workload |
| J2b | `sh-vpc` (host) | `sa-tf-wl-001` | `compute.networkUser` | Dùng subnet Shared VPC để tạo VM (`subnetworks.use`) |
| J3 | `management` | `sa-tf-mgmt-001` | `logging.admin` | Log Sinks / Buckets / Views |
| J3 | `management` | `sa-tf-mgmt-001` | `monitoring.admin` | Dashboards / Alert Policies |
| J3 | `management` | `sa-tf-mgmt-001` | `storage.admin` | GCS Archive bucket |
| J3 | `management` | `sa-tf-mgmt-001` | `resourcemanager.projectIamAdmin` | `bucketWriter` cho Sink |
| J4 | `hub-net` | `sa-tf-conn-001` | `serviceusage.serviceUsageConsumer` | `user_project_override` → billing_project |
| J4 | `sample-app` | `sa-tf-wl-001` | `serviceusage.serviceUsageConsumer` | `user_project_override` → billing_project |
| J4 | `management` | `sa-tf-mgmt-001` | `serviceusage.serviceUsageConsumer` | `user_project_override` → billing_project |
| J4 | `management` | `sa-tf-sec-001` | `serviceusage.serviceUsageConsumer` | `user_project_override` → billing_project |
| J5 | `sample-app` | `sa-tf-sec-001` | `resourcemanager.projectIamAdmin` | Gắn binding IAP / OS-login |
| J5 | `hub-net` | `sa-tf-sec-001` | `resourcemanager.projectIamAdmin` | Gắn binding IAP / OS-login |
| J5 | `sh-vpc` | `sa-tf-sec-001` | `resourcemanager.projectIamAdmin` | Gắn binding IAP / OS-login |
| J6 | `sample-app` | `sa-tf-mgmt-001` | `monitoring.admin` | Link vào metric scope của management |
| J6 | `hub-net` | `sa-tf-mgmt-001` | `monitoring.admin` | Link vào metric scope của management |
| J6 | `sh-vpc` | `sa-tf-mgmt-001` | `monitoring.admin` | Link vào metric scope của management |

> [!NOTE]
> Nhóm **J2b / J4 / J5 / J6** sinh ra từ thực tế triển khai: VM dùng subnet Shared VPC cần `compute.networkUser` trên **host project**; mọi stack hạ nguồn đặt `user_project_override=true` nên cần `serviceUsageConsumer` trên billing_project; security gắn binding IAP lên 3 project nên cần `projectIamAdmin`; management gom project vào metric scope nên cần `monitoring.admin` trên **cả** scoping project lẫn từng project bị thêm.

### 💰 Billing bổ sung — `[7] POSTORG_BILLING_BINDINGS`

| Billing Account | Service Account | Role |
|:----------------|:----------------|:-----|
| Budget Account | `sa-tf-mgmt-001` | `billing.costsManager` |

---

## 🔒 Cô lập State file qua IAM Conditions

Để thực thi nghiêm ngặt **Separation of Duties**, mỗi Runner SA chỉ được đọc/ghi đúng prefix state của mình trên GCS bucket (`STATE_BUCKET`). Việc này dùng điều kiện **CEL (Common Expression Language)** gắn trên IAM binding của bucket.

### ✍️ Quyền GHI prefix của chính mình — `[4] STATE_OWN_BINDINGS`

Mỗi SA được cấp `roles/storage.objectAdmin` **chỉ trên** prefix tương ứng:

| Service Account | Prefix được ghi |
|:----------------|:----------------|
| `sa-tf-org-001` | `terraform/org/` |
| `sa-tf-conn-001` | `terraform/connectivity/` |
| `sa-tf-sec-001` | `terraform/security/` |
| `sa-tf-wl-001` | `terraform/workload/` |
| `sa-tf-mgmt-001` | `terraform/management/` |

### 👁️ Quyền ĐỌC prefix upstream — `[5] STATE_UPSTREAM_BINDINGS`

Để hỗ trợ tiêu thụ output liên-stack qua `terraform_remote_state`, các stack downstream được cấp `roles/storage.objectViewer` (chỉ đọc) trên state của các stack upstream:

```mermaid
graph TD
    classDef sa fill:#2d3748,stroke:#4a5568,color:#fff;
    classDef st fill:#e8f0fe,stroke:#1a73e8,color:#174ea6;

    connSA["🔵 sa-tf-conn"]:::sa
    secSA["🔴 sa-tf-sec"]:::sa
    wlSA["🟢 sa-tf-wl"]:::sa
    mgmtSA["🟡 sa-tf-mgmt"]:::sa

    orgState["📂 org/"]:::st
    connState["📂 connectivity/"]:::st
    wlState["📂 workload/"]:::st

    connSA -->|Read-Only| orgState
    secSA  -->|Read-Only| orgState

    wlSA -->|Read-Only| orgState
    wlSA -->|Read-Only| connState

    mgmtSA -->|Read-Only| orgState
    mgmtSA -->|Read-Only| connState
    mgmtSA -->|Read-Only| wlState
```

| Service Account | Đọc được state của |
|:----------------|:-------------------|
| `sa-tf-conn-001` | `org` |
| `sa-tf-sec-001` | `org` |
| `sa-tf-wl-001` | `org`, `connectivity` |
| `sa-tf-mgmt-001` | `org`, `connectivity`, `workload` |

> [!WARNING]
> Nếu một SA cố ghi vào prefix nằm ngoài phạm vi được cấp, GCS lập tức trả về **Access Denied** — bảo vệ state của môi trường khỏi việc ghi đè nhầm lẫn.

---

## 👤 Quyền cho Quản trị viên (Human Identity)

Khác với Runner SA (phục vụ IaC), quyền cho **con người** được quản lý khai báo trong stack `security/` tại [security/iam.tf](../../security/iam.tf), áp cho danh sách `admin_principals` (user hoặc group).

### 🏛️ Role cấp Organization

Mỗi principal trong `admin_principals` được cấp các role org-level sau (tích Descartes role × principal):

`organizationAdmin` · `billing.user` · `projectCreator` · `folderAdmin` · `iam.serviceAccountAdmin` · `compute.osLogin` · `monitoring.viewer` · `logging.privateLogViewer`

### 🚪 Truy cập VM qua Cloud IAP — *không Bastion, không IP Public*

Trên các project `sample-app`, `hub-net`, `sh-vpc`, mỗi admin được cấp:

| Role | Mục đích |
|:-----|:---------|
| `roles/iap.tunnelResourceAccessor` | Mở SSH tunnel qua IAP |
| `roles/compute.osAdminLogin` | Đăng nhập SSH với quyền admin (đi cùng OS Login) |

```bash
gcloud compute ssh <VM> \
  --project <PROJECT> \
  --zone asia-southeast1-b \
  --tunnel-through-iap
```

### 🔍 Log View phân quyền (có điều kiện CEL)

Admin được cấp `roles/logging.viewAccessor` **giới hạn** đúng vào log view `gcp-sg-logview-sample-app-001` trong project `management` — chỉ đọc đúng logs của nguồn được phép, không thấy logs các project khác.

---

## 🤖 Runtime SA cho Workload

Ngoài 5 Runner SA phục vụ IaC, dự án còn tạo các **Runtime Service Account** gắn vào VM/workload (Phase B — script [scripts/03-runtime-sa.sh](../../scripts/03-runtime-sa.sh)):

### ❓ Tại sao lại có Runtime SA riêng cho từng project?

Cần phân biệt rõ **hai loại danh tính máy** trong landing zone — chúng phục vụ hai mục đích hoàn toàn khác nhau:

| | 🏗️ **Runner SA** (5 cái) | 🤖 **Runtime SA** (theo project) |
|:--|:--|:--|
| **Ai dùng** | Terraform khi `apply` hạ tầng | Chính VM / workload khi đang chạy |
| **Khi nào hoạt động** | Lúc triển khai (deploy time) | Lúc vận hành (run time), 24/7 |
| **Đặt ở đâu** | Seed Project (tập trung) | Trong chính project workload |
| **Quyền** | Tạo/sửa/xóa tài nguyên | Tối thiểu để gửi telemetry |

Lý do **mỗi project workload có một Runtime SA riêng** thay vì dùng chung một SA hay dùng *Default Compute SA* của Google:

- 🎯 **Least Privilege theo từng project** — VM của `sample-app` chỉ có đúng quyền của `sample-app`. Nếu một VM bị xâm nhập, kẻ tấn công không thể dùng danh tính đó để đụng tới project khác — **cô lập blast radius** xuống từng project.
- 🔍 **Audit rõ ràng** — mọi hành động trong Cloud Audit Log gắn đích danh `gcp-sg-sa-sample-app-001`, biết ngay request đến từ workload nào, không bị trộn lẫn.
- 🚫 **Tránh Default Compute SA** — SA mặc định của Compute Engine có quyền `Editor` quá rộng trên toàn project; Org Policy `iam.automaticIamGrantsForDefaultServiceAccounts` chặn nó, nên ta **chủ động** cấp SA tự quản lý với quyền tối thiểu.
- ♻️ **Vòng đời độc lập** — xóa/tạo lại workload của một project không ảnh hưởng danh tính của project khác.

| Nhóm | Account ID | Project | `actAs` | Vai trò |
|:-----|:-----------|:--------|:-------:|:--------|
| `app` | `gcp-sg-sa-sample-app-001` | sample-app | ✅ | Runtime SA cho workload Sample-app |
| `tools` | `gcp-sg-sa-hub-net-001` | hub-net | ❌ | Runtime SA cho hub-net |
| `tools` | `gcp-sg-sa-sh-vpc-001` | sh-vpc | ❌ | Runtime SA cho sh-vpc |

Mọi Runtime SA đều nhận **role cố định** tối thiểu để gửi telemetry:

- `roles/monitoring.metricWriter`
- `roles/logging.logWriter`

> [!NOTE]
> Cờ `actAs = yes` nghĩa là `sa-tf-wl-001` được cấp `iam.serviceAccountUser` để gắn (attach) Runtime SA đó vào VM khi tạo instance.

---

## ⚙️ Quản lý phân quyền ở đâu?

Toàn bộ ma trận phân quyền tách bạch **dữ liệu** và **logic** để dễ bảo trì:

### ❓ Tại sao phân quyền bootstrap bằng script tay mà không dùng Terraform?

Đây là một lựa chọn thiết kế có chủ đích, không phải thiếu sót. Các quyền **gốc** (Org/Billing/Token Creator/State bucket) được cấp qua [scripts/01-bootstrap.sh](../../scripts/01-bootstrap.sh) chứ không qua Terraform vì:

- 🔄 **Bài toán "con gà – quả trứng" (chicken-and-egg)** — Terraform muốn chạy thì phải *đã có* một Runner SA đủ quyền và một State bucket để lưu state. Nhưng chính những thứ đó (SA, quyền Org, bucket) lại là cái cần được tạo đầu tiên. Không thể dùng Terraform để tạo ra chính điều kiện để Terraform chạy → phải có một bước bootstrap bằng `gcloud` nằm **ngoài** vòng đời Terraform.
- 🔑 **Tránh quyền Org-Admin nằm trong state** — Nếu cấp quyền cấp tổ chức bằng Terraform, những binding cực kỳ nhạy cảm (`organizationAdmin`…) sẽ bị ghi vào file state. Ta giữ chúng ngoài state để giảm bề mặt rủi ro.
- 🥚 **Trách nhiệm một lần (one-time)** — Bootstrap là thao tác thiết lập nền móng, chạy **một lần** bởi Org Admin lúc khởi tạo; nó không thuộc chu kỳ `plan/apply` lặp lại của hạ tầng thường ngày.
- 🧩 **Ranh giới quyền sạch** — Con người (Org Admin) làm bước bootstrap một lần; sau đó mọi thứ do SA đảm nhiệm. Giới hạn rõ "việc của người" vs "việc của máy".

> [!NOTE]
> Để nhất quán, quyền **cấp project** sau khi apply `org/` cũng được gom vào script ([scripts/02-post-org-roles.sh](../../scripts/02-post-org-roles.sh)) thay vì nằm rải rác trong Terraform — toàn bộ bản đồ IAM "runner" nằm một chỗ ([scripts/roles.sh](../../scripts/roles.sh)), dễ audit. Ngược lại, quyền cho **con người** (admin_principals) lại được quản lý bằng Terraform trong [security/iam.tf](../../security/iam.tf), vì chúng nằm *trong* phạm vi hạ tầng đã được bootstrap và cần thay đổi theo thời gian như một phần của IaC.

| File | Vai trò |
|:-----|:--------|
| [scripts/config.sh](../../scripts/config.sh) | Biến cấu hình: Org ID, Billing, Group email, Seed Project, email 5 Runner SA |
| [scripts/roles.sh](../../scripts/roles.sh) | **Bảng dữ liệu phân quyền** — file duy nhất cần sửa khi thêm/bớt role |
| [scripts/lib.sh](../../scripts/lib.sh) | Hàm tiện ích dùng chung |
| [scripts/01-bootstrap.sh](../../scripts/01-bootstrap.sh) | Tạo SA, gán role Org/Billing, Token Creator, State bucket |
| [scripts/02-post-org-roles.sh](../../scripts/02-post-org-roles.sh) | Gán role cấp Project/Billing **sau khi** apply `org/` |
| [scripts/03-runtime-sa.sh](../../scripts/03-runtime-sa.sh) | Tạo Runtime SA cho VM/workload (Phase B) |
| [security/iam.tf](../../security/iam.tf) | Quyền cấp cho con người (admin_principals): Org roles, IAP, Log View |

> [!TIP]
> Muốn thêm một role cho Runner SA? Chỉ cần thêm một dòng vào bảng tương ứng trong [scripts/roles.sh](../../scripts/roles.sh) rồi chạy lại script — không cần đụng vào logic.
