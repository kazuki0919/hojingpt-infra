resource "google_spanner_instance" "default" {
  name             = var.name
  config           = var.config
  display_name     = var.name
  num_nodes        = var.num_nodes
  processing_units = var.processing_units
  labels           = var.labels
  project          = var.project

  timeouts {
    create = var.spanner_instance_timeout
    update = var.spanner_instance_timeout
    delete = var.spanner_instance_timeout
  }

  lifecycle {
    ignore_changes = [
      processing_units,
      num_nodes,
    ]
  }
}

resource "google_spanner_database" "default" {
  instance                 = google_spanner_instance.default.name
  name                     = var.db
  ddl                      = var.ddl_queries
  deletion_protection      = var.deletion_protection
  version_retention_period = "7d"
  database_dialect         = "GOOGLE_STANDARD_SQL"

  timeouts {
    create = var.spanner_db_timeout
    update = var.spanner_db_timeout
    delete = var.spanner_db_timeout
  }
}
