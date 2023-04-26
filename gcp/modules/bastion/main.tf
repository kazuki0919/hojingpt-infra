resource "google_service_account" "default" {
  account_id   = var.name
  display_name = var.name
}

resource "google_compute_firewall" "default" {
  name    = var.name
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]
}

resource "google_compute_instance_template" "default" {
  name_prefix    = "${var.name}-"
  project        = var.project
  region         = var.region
  description    = "Bastion Host Instance Template"
  tags           = ["bastion"]
  labels         = var.labels
  machine_type   = var.machine_type
  can_ip_forward = true

  metadata_startup_script = file("${path.module}/startup.sh")

  metadata = {
    "enable-oslogin" = "TRUE"
  }

  disk {
    # Adopted ubuntu for long-term support
    source_image = var.source_image
    auto_delete  = true
    boot         = true
    disk_type    = "pd-ssd"
    disk_size_gb = var.disk_size
    labels       = var.labels
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id
    nic_type   = "GVNIC"

    access_config {}
  }

  scheduling {
    automatic_restart           = false
    instance_termination_action = "STOP"
    min_node_cpus               = 0
    on_host_maintenance         = "TERMINATE"
    preemptible                 = true
    provisioning_model          = "SPOT"
  }

  service_account {
    # It is set up according to best practices.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "default" {
  name               = var.name
  base_instance_name = var.name
  project            = var.project
  region             = var.region
  description        = "Bastion Host Managed Instance Group"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.default.id
  }
}
