resource "google_compute_instance" "standard" {
  boot_disk {
    auto_delete = true
    device_name = "persistent-disk-0"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230425"
      size  = 10
      type  = "pd-ssd"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = true
  deletion_protection = false
  description         = "Bastion Host Instance Template"
  enable_display      = false

  labels = var.labels

  machine_type = var.machine_type

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = "#! /bin/bash\nset -euo pipefail\n\nexport DEBIAN_FRONTEND=noninteractive\napt-get update && apt-get install -y zip unzip jq redis-tools mysql-client\n"
  }

  name = var.name

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    nic_type   = "GVNIC"
    subnetwork = var.subnetwork_id
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = google_service_account.default.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  tags = ["bastion"]
  zone = "asia-northeast1-b"
}
