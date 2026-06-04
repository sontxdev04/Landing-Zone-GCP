# =============================================================================
# ORG · Organization Policies — guardrail cấp tổ chức
# -----------------------------------------------------------------------------
# Mục đích : Áp các lan can (guardrail) không thể vượt qua ở cấp Organization;
#            kể cả Owner của project con cũng không thể vi phạm.
# Phụ thuộc: depends_on module.lz-prj-hub-net — tạo project TRƯỚC khi siết policy.
# =============================================================================

# Yêu cầu OS Login trên mọi VM
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

# Không tạo VPC mặc định khi tạo project mới
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

# Cấm IP ngoài trên mọi VM trong toàn Organization
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

# Không ngoại lệ cấp project — mọi truy cập VM đi qua Cloud IAP (không cần IP ngoài).

# Tắt khả năng tạo khóa Service Account trong toàn Organization
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


# Yêu cầu Shielded VM trên mọi instance
resource "google_org_policy_policy" "gcp-sg-org-policy-require-shielded-vm-001" {
  name   = "organizations/${var.org_id}/policies/compute.requireShieldedVm"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [module.lz-prj-hub-net]
}

# Bắt buộc uniform bucket-level access trên mọi Cloud Storage bucket
resource "google_org_policy_policy" "gcp-sg-org-policy-uniform-bucket-access-001" {
  name   = "organizations/${var.org_id}/policies/storage.uniformBucketLevelAccess"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [module.lz-prj-hub-net]
}

# Giới hạn vị trí tài nguyên trong asia-southeast1
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


