# Org policy: require OS Login on all VMs
resource "google_org_policy_policy" "gcp-sg-org-policy-require-oslogin-001" {
  name   = "organizations/${var.org_id}/policies/compute.requireOsLogin"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [module.lz-prj-hub-net]
}

# Org policy: skip default VPC creation in new projects
resource "google_org_policy_policy" "gcp-sg-org-policy-skip-default-network-001" {
  name   = "organizations/${var.org_id}/policies/compute.skipDefaultNetworkCreation"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [module.lz-prj-hub-net]
}

# Org policy: deny external IP on all VMs across the organization
resource "google_org_policy_policy" "gcp-sg-org-policy-deny-vm-external-ip-001" {
  name   = "organizations/${var.org_id}/policies/compute.vmExternalIpAccess"
  parent = "organizations/${var.org_id}"

  spec {
    inherit_from_parent = false
    rules {
      deny_all = true
    }
  }

  depends_on = [module.lz-prj-hub-net]
}

# Project-level exception: allow external IP for the Bastion Host in shared-access project
resource "google_org_policy_policy" "gcp-sg-org-policy-allow-vm-external-ip-bastion-001" {
  name   = "projects/${module.lz-prj-sh-access.project_id}/policies/compute.vmExternalIpAccess"
  parent = "projects/${module.lz-prj-sh-access.project_id}"

  spec {
    inherit_from_parent = false
    rules {
      values {
        allowed_values = [
          "projects/${module.lz-prj-sh-access.project_id}/zones/${var.zone_sg_b}/instances/gcp-sg-vm-bastion-001",
        ]
      }
    }
  }

  depends_on = [
    google_org_policy_policy.gcp-sg-org-policy-deny-vm-external-ip-001,
    module.lz-prj-sh-access,
  ]
}

# Org policy: disable Service Account key creation across the organization
resource "google_org_policy_policy" "gcp-sg-org-policy-disable-sa-key-001" {
  name   = "organizations/${var.org_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [module.lz-prj-hub-net]
}

# Project-level exception: allow Service Account key creation in shared-access project
resource "google_org_policy_policy" "gcp-sg-org-policy-allow-sa-key-sh-access-001" {
  name   = "projects/${module.lz-prj-sh-access.project_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "projects/${module.lz-prj-sh-access.project_id}"

  spec {
    inherit_from_parent = false
    rules {
      enforce = false
    }
  }

  depends_on = [module.lz-prj-sh-access]
}

# Org policy: require Shielded VM on all instances
resource "google_org_policy_policy" "gcp-sg-org-policy-require-shielded-vm-001" {
  name   = "organizations/${var.org_id}/policies/compute.requireShieldedVm"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }

  depends_on = [module.lz-prj-hub-net]
}

# Org policy: enforce uniform bucket-level access on all Cloud Storage buckets
resource "google_org_policy_policy" "gcp-sg-org-policy-uniform-bucket-access-001" {
  name   = "organizations/${var.org_id}/policies/storage.uniformBucketLevelAccess"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }

  depends_on = [module.lz-prj-hub-net]
}

# Org policy: restrict resource locations to asia-southeast1
resource "google_org_policy_policy" "gcp-sg-org-policy-restrict-locations-001" {
  name   = "organizations/${var.org_id}/policies/gcp.resourceLocations"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      values {
        allowed_values = ["in:asia-southeast1-locations"]
      }
    }
  }

  depends_on = [module.lz-prj-hub-net]
}


