variable "name" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

# variable "project" {
#   type = string
# }

# variable "descript" {
#   type    = string
#   default = ""
# }

resource "google_compute_network" "default" {
  name                            = "${var.name}${var.name_suffix}"
#   auto_create_subnetworks         = false
#   routing_mode                    = var.routing_mode
#   project                         = var.project
#   description                     = var.description
#   delete_default_routes_on_create = var.delete_default_internet_gateway_routes
#   mtu                             = 1460
}

variable "public_cidr_range" {
  default = "10.100.0.0/16"
}

variable "private_cidr_range" {
  default = "10.101.0.0/16"
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.name}-public${var.name_suffix}"
  ip_cidr_range = var.public_cidr_range
  network       = google_compute_network.default.name

  private_ip_google_access = false
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.name}-private${var.name_suffix}"
  ip_cidr_range = var.private_cidr_range
  network       = google_compute_network.default.name

  private_ip_google_access = true
}
