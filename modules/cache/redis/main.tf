variable "name" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-northeast1"
}

resource "google_redis_instance" "cache" {
  name           = "ha-memory-cache"
  tier           = "STANDARD_HA"
  memory_size_gb = 1

  location_id             = "asia-northeast1a"
  alternative_location_id = "us-central1-f"

  authorized_network = data.google_compute_network.redis-network.id

  redis_version     = "REDIS_6_X"
  display_name      = "Terraform Test Instance"
  reserved_ip_range = "192.168.0.0/29"

  labels = {
    project    = "my_val"
    other_key = "other_val"
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "TUESDAY"
      start_time {
        hours = 0
        minutes = 30
        seconds = 0
        nanos = 0
      }
    }
  }
}