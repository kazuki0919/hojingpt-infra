variable "name" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "region" {
  type = string
}

variable "tier" {
  type = string
}

variable "database_version" {
  type = string
}

resource "google_sql_database_instance" "default" {
  name             = "${var.name}${var.name_suffix}"
  database_version = var.database_version

  settings {
    tier                        = var.tier
    deletion_protection_enabled = true
    # availability_type = "REGIONAL"

    # backup_configuration {
    #   enabled    = true
    #   binary_log_enabled = true
    #   start_time = "00:00"
    # }

    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 4500
      record_application_tags = true
      record_client_address   = true
    }

    maintenance_window {
      day          = 2
      hour         = 18
      update_track = "canary"
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
