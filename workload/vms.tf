# Workload stack — example Bastion VM; add your own workloads here

data "google_project" "gcp-sg-prj-sh-access-001" {
  project_id = local.org.project_id_sh_access
}

# Bastion service account (created manually via gcloud — see README §6.1)
data "google_service_account" "sa-sh-access" {
  account_id = "gcp-sg-sa-sh-access-001"
  project    = local.org.project_id_sh_access
}

# Startup script: install Google Cloud Ops Agent (logging + monitoring)
locals {
  ops_agent_startup_script = <<-EOT
    #!/bin/bash
    if ! systemctl is-active --quiet google-cloud-ops-agent; then
      curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
      bash add-google-cloud-ops-agent-repo.sh --also-install
    fi
  EOT
}

# Bastion Host (example workload VM)
resource "google_compute_instance" "gcp-sg-vm-bastion-001" {
  name         = "gcp-sg-vm-bastion-001"
  machine_type = var.bastion_machine_type
  zone         = var.zone_sg_b
  project      = data.google_project.gcp-sg-prj-sh-access-001.project_id

  boot_disk {
    initialize_params {
      image = var.bastion_image
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network            = local.conn.vpc_shared_access_id
    subnetwork         = local.conn.snet_shared_access_id
    subnetwork_project = data.google_project.gcp-sg-prj-sh-access-001.project_id
    network_ip         = "10.50.1.100"

    access_config {
      nat_ip       = local.conn.bastion_public_ip
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = data.google_service_account.sa-sh-access.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  deletion_protection = true

  metadata                = { enable-oslogin = "TRUE" }
  metadata_startup_script = local.ops_agent_startup_script
  labels = {
    managed_by    = "terraform"
    stack         = "workload"
    environment   = "prod"
    project       = "techshop"
    resource_name = "bastion-001"
    role          = "bastion"
  }
  tags = ["bastion", "allow-ssh-external"]
}
