resource "google_compute_network" "default" {
  name                    = "${var.name}${var.name_suffix}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project
}

resource "google_compute_subnetwork" "default" {
  name                     = "${var.name}-default${var.name_suffix}"
  ip_cidr_range            = "10.100.0.0/16"
  network                  = google_compute_network.default.name
  private_ip_google_access = true
}

resource "google_vpc_access_connector" "default" {
  name           = "${var.name}-default${var.name_suffix}"
  region         = var.region
  ip_cidr_range  = "10.8.0.0/28"
  network        = google_compute_network.default.name
  machine_type   = "e2-micro"
  min_instances  = 2
  max_instances  = 10
  max_throughput = 1000
}

resource "google_compute_global_address" "default" {
  name          = "${var.name}-default${var.name_suffix}"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  network       = google_compute_network.default.id
  address       = "10.200.0.0"
  prefix_length = 16
}

resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.default.name]
}

# see: https://zenn.dev/btc4043/articles/5d9859d3226f7d

# # Cloud Router (for asia-northeast1)
# resource "google_compute_router" "default" {
#   name    = "${var.name}${var.name_suffix}"
#   region  = google_compute_subnetwork.default.region
#   network = google_compute_network.default.id
# }

# # External ip for Cloud NAT
# resource "google_compute_address" "nat_external_ipaddress" {
#   name = "${var.name}-nat-external-ip${var.name_suffix}"
# }

# # Cloud NAT
# resource "google_compute_router_nat" "an1_nat" {
#   name                               = "btc4043-an1-nat"
#   router                             = google_compute_router.default.name
#   region                             = google_compute_router.default.region
#   nat_ip_allocate_option             = "MANUAL_ONLY"
#   nat_ips                            = google_compute_address.nat_external_ipaddress.*.self_link
#   source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

#   subnetwork {
#     name                    = google_compute_subnetwork.default.id
#     source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
#   }

#   subnetwork {
#     name                    = google_compute_subnetwork.default.id
#     source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
#   }
# }
