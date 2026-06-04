# 🛠️ GCP Landing Zone — Day-2 Operations Runbook

This runbook acts as the primary operational resource for SREs and Cloud Platform administrators managing the landing zone environment.

---

## 🛑 1. Lifecycle Operations (Apply / Destroy Order)

Because stacks reference each other's outputs via `terraform_remote_state` data sources, you must respect the dependency tree when applying updates or tearing down environments.

```
TRIỂN KHAI XUÔI (APPLY ORDER)
[ 1. org ] ──► [ 2. connectivity ] & [ 3. security ] ──► [ 4. workload ] ──► [ 5. management ]

THU HỒI NGƯỢC (DESTROY ORDER)
[ 5. management ] ──► [ 4. workload ] ──► [ 3. security ] & [ 2. connectivity ] ──► [ 1. org ]
```

> [!CAUTION]  
> Failure to follow the correct order will result in state locks, compilation errors, and broken resource dependencies.

---

## 📈 2. Common Day-2 Tasks

### Scenario 2.1: Registering a New Workload Subnet & Project
When an application team requests a new isolated environment:

```
[Determine CIDR] ──► [Add Subnet in connectivity] ──► [Provision Project in org] ──► [Authorize workload SA via scripts]
```

1. **CIDR Allocation**: Allocate a non-overlapping dải IP block (e.g., `10.20.2.0/24`) from your IPAM database.
2. **Connectivity Update**:
   - Open [connectivity/subnets.tf](connectivity/subnets.tf).
   - Add the subnet block under `gcp-sg-vpc-shared-001` network.
   - Run `terraform apply` in the `connectivity` folder.
3. **Org Project Updates**:
   - Open [org/projects.tf](org/projects.tf).
   - Define the new project using the Project Factory block and assign it to the `fldr-workload` folder.
   - Run `terraform apply` in the `org` folder.
4. **Access Control**:
   - Run `./scripts/02-post-org-roles.sh` to associate permissions on the new project.
   - Grant the workload runner SA (`sa-tf-wl-001`) the `roles/compute.networkUser` permission on the new subnet to allow instantiating VMs.

---

### Scenario 2.2: Connecting VMs to Central Observability
To enable a virtual machine to send logs and health metrics back to SRE dashboards:

1. **Install Ops Agent**:
   Verify startup scripts or VM templates configure and enable the Google Cloud Ops Agent:
   ```bash
   curl -sSO https://dl.google.com/cloudagents/add-googlecloud-ops-agent-repo.sh
   sudo bash add-googlecloud-ops-agent-repo.sh --also-install
   ```
2. **Register Project**:
   - Open [management/monitoring.tf](management/monitoring.tf).
   - Append the new project ID to the monitored projects list.
   - Run `terraform apply` in the `management` folder to expand the SRE metric collection scope.

---

## ⚡ 3. Operational Guardrails

> [!WARNING]  
> Never apply changes to the following resource blocks without testing them on a Sandbox folder project first.

- **Organization Policies ([org/org-policies.tf](org/org-policies.tf))**: Changing constraints such as `compute.vmExternalIpAccess` or `iam.disableServiceAccountKeyCreation` globally can immediately break current VM configurations or block CI/CD pipeline access.
- **Firewall Policies ([security/org-fw-policies.tf](security/org-fw-policies.tf))**: Modifying high-level hierarchical rules can block connectivity chéo between Spoke and Hub networks.
- **VM Deletion Protection**: Compute instances (e.g., in [workload/vms.tf](workload/vms.tf)) have `deletion_protection = true` enabled. You must toggle this attribute to `false` and apply changes before attempting to destroy a stack.
