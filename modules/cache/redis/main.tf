variable "name" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-northeast1"
}

# resource "google_redis_instance" "default" {
#   name               = var.name
#   tier               = "STANDARD_HA"
#   memory_size_gb     = 1
#   authorized_network = "projects/my-project-id/global/networks/default"
#   location_id        = "us-central1-a"
#   redis_version      = "REDIS_5_0"
# }

# resource "google_redis_instance" "basic" {
#   name           = var.name
#   tier           = "BASIC"
#   memory_size_gb = 2
#   region         = var.region
#   redis_version  = "REDIS_6_X"
# }
