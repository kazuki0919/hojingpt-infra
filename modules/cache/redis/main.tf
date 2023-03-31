resource "google_redis_instance" "default" {
  name           = var.name
  tier           = var.tier
  memory_size_gb = var.memory_size

  location_id = var.zone

  authorized_network = var.network_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version = var.redis_version

  replica_count      = var.replica_count
  read_replicas_mode = var.read_replicas_mode

  labels = var.labels

  persistence_config {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "ONE_HOUR"
  }

  maintenance_policy {
    # For UTC+9, it is 3:00AM on Monday.
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 18
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }
}
