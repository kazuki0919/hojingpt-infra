resource "google_compute_instance" "default" {
  name                = var.name
  zone                = var.zone
  machine_type        = var.machine_type
  labels              = var.labels
  tags                = var.tags
  can_ip_forward      = false
  deletion_protection = true
  enable_display      = false

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    email  = var.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  network_interface {
    nic_type   = var.nic_type
    subnetwork = var.subnetwork_id

    access_config {
      network_tier = "PREMIUM"
    }
  }

  boot_disk {
    auto_delete = true
    device_name = var.name
    mode        = "READ_WRITE"

    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}
