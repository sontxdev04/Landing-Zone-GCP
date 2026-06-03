# Workload stack — example Bastion VM; add your own workloads here

data "google_project" "gcp-sg-prj-sh-access-001" {
  project_id = local.org.project_id_sh_access
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
  machine_type = "e2-micro"
  zone         = "asia-southeast1-b"
  project      = data.google_project.gcp-sg-prj-sh-access-001.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
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
    email  = local.sec.sa_sh_access_email
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
