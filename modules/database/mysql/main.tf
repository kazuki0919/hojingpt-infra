resource "google_sql_database_instance" "default" {
  name             = "${var.name}${var.name_suffix}"
  database_version = var.database_version

  settings {
    tier                        = var.tier
    deletion_protection_enabled = true
    availability_type           = var.availability_type

    disk_autoresize       = true
    disk_autoresize_limit = 0
    disk_size             = var.disk_size
    disk_type             = "PD_SSD"

    backup_configuration {
      enabled                        = true
      binary_log_enabled             = true
      start_time                     = var.backup_start_time
      location                       = var.backup_location
      transaction_log_retention_days = var.backup_transaction_log_retention_days
      point_in_time_recovery_enabled = false # false for mysql

      backup_retention_settings {
        retained_backups = var.backup_retentions_days
        retention_unit   = "COUNT"
      }
    }

    dynamic "insights_config" {
      for_each = var.query_insights == null ? [] : [var.query_insights]
      content {
        query_insights_enabled  = true
        query_plans_per_minute  = insights_config.value.query_plans_per_minute
        query_string_length     = insights_config.value.query_string_length
        record_application_tags = true
        record_client_address   = true
      }
    }

    ip_configuration {
      allocated_ip_range                            = var.allocated_ip_range
      enable_private_path_for_google_cloud_services = false
      ipv4_enabled                                  = false
      private_network                               = var.private_network
      require_ssl                                   = false
    }

    dynamic "maintenance_window" {
      for_each = var.maintenance_window == null ? [] : [var.maintenance_window]
      content {
        day          = maintenance_window.value.day
        hour         = maintenance_window.value.hour
        update_track = maintenance_window.value.update_track
      }
    }
  }
}

resource "google_sql_database" "default" {
  name      = var.name
  instance  = google_sql_database_instance.default.name
  charset   = "utf8mb4"
  collation = "utf8mb4_bin"
}

data "google_secret_manager_secret_version" "root_password" {
  secret = "${var.name}-mysql-root-pwd${var.name_suffix}"
}

resource "google_sql_user" "root" {
  name     = "root"
  instance = google_sql_database_instance.default.name
  host     = "%"
  password = data.google_secret_manager_secret_version.root_password.secret_data
}
