output "default_network" {
  value = google_compute_network.default
}

output "default_subnetwork" {
  value = google_compute_subnetwork.default
}

output "default_vpc_access_connector" {
  value = google_vpc_access_connector.default
}

output "default_global_address" {
  value = google_compute_global_address.default
}
