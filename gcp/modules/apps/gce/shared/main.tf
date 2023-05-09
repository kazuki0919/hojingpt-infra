variable "name" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "network_id" {
  type = string
}

resource "google_service_account" "default" {
  account_id   = "${var.name}-gce${var.name_suffix}"
  display_name = "${var.name}-gce${var.name_suffix}"
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.name}-allow-ssh${var.name_suffix}"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "http" {
  name    = "${var.name}-allow-http${var.name_suffix}"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "https" {
  name    = "${var.name}-allow-https${var.name_suffix}"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

output "service_account_email" {
  value = google_service_account.default.email
}
