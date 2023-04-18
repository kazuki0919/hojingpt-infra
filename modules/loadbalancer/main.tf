variable "name" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "domains" {
  type = list(string)
}

variable "app_service_name" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

resource "google_compute_global_address" "default" {
  project    = var.project
  name       = "${var.name}-lb${var.name_suffix}"
  ip_version = "IPV4"
}

resource "google_compute_managed_ssl_certificate" "default" {
  project     = var.project
  name        = "${var.name}-lb${var.name_suffix}"
  description = "Managed SSL Certificate for ${var.name}-lb${var.name_suffix}"

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = var.domains
  }
}

resource "google_compute_region_network_endpoint_group" "app" {
  name                  = "${var.name}-app${var.name_suffix}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = var.app_service_name
  }
}

resource "google_compute_backend_service" "app" {
  name                  = "${var.name}-app${var.name_suffix}"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  # custom_request_headers  = ["host: ${google_compute_region_network_endpoint_group.app.fqdn}"]

  backend {
    group = google_compute_region_network_endpoint_group.app.id
  }
}

resource "google_compute_url_map" "default" {
  project         = var.project
  name            = "${var.name}-lb-default${var.name_suffix}"
  default_service = google_compute_backend_service.app.self_link
}

# resource "google_compute_url_map" "https_redirect" {
#   project = var.project
#   name    = "${var.name}-lb-http-redirect${var.name_suffix}"

#   default_url_redirect {
#     https_redirect         = true
#     redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
#     strip_query            = false
#   }
# }

# # HTTP proxy when http forwarding is true
# resource "google_compute_target_http_proxy" "default" {
#   project = var.project
#   name    = "${var.name}-http-proxy${var.name_suffix}"
#   url_map = var.https_redirect == false ? local.url_map : join("", google_compute_url_map.https_redirect.*.self_link)
# }

resource "google_compute_target_https_proxy" "default" {
  project          = var.project
  name             = "${var.name}-https-proxy${var.name_suffix}"
  url_map          = google_compute_url_map.default.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.default.self_link]
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project
  name                  = "${var.name}-https${var.name_suffix}"
  target                = google_compute_target_https_proxy.default.self_link
  ip_address            = google_compute_global_address.default.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
