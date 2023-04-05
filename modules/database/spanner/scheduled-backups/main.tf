variable "name" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "function_bucket" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "database_id" {
  type = string
}

resource "google_service_account" "scheduled_backups" {
  account_id   = "${var.name}-spanner-auto-backup"
  display_name = "Scheduled Backups for Spanner"
}

# see: https://github.com/cloudspannerecosystem/scheduled-backups/tree/9314e22a182c91d41d7877e784d8521e51d211b5
resource "google_pubsub_topic" "scheduled_backups" {
  name = "${var.name}-spanner-scheduled-backups${var.name_suffix}"
}

resource "google_cloud_scheduler_job" "scheduled_backups" {
  name        = "${var.name}-spanner-scheduled-backups${var.name_suffix}"
  description = "Spanner's regular backup schedule"
  schedule    = "0 3 * * *"
  time_zone   = "Asia/Tokyo"

  pubsub_target {
    topic_name = google_pubsub_topic.scheduled_backups.id

    data = base64encode(
      jsonencode({
        database = "projects/${var.project}/instances/${var.instance_id}/databases/${var.database_id}"
        expire   = "168h"
      })
    )
  }
}

data "archive_file" "scheduled_backups" {
  type        = "zip"
  source_dir  = abspath("${path.module}/src")
  output_path = "${path.module}/bin/scheduled_backups.zip"
}

resource "google_storage_bucket_object" "scheduled_backups" {
  name   = "scheduled_backups.${data.archive_file.scheduled_backups.output_md5}.zip"
  bucket = var.function_bucket
  source = data.archive_file.scheduled_backups.output_path
}

resource "google_cloudfunctions_function" "scheduled_backups" {
  name                = "${var.name}-spanner-scheduled-backups${var.name_suffix}"
  project             = var.project
  region              = var.region
  ingress_settings    = "ALLOW_INTERNAL_AND_GCLB"
  available_memory_mb = 256
  entry_point         = "SpannerCreateBackup"
  runtime             = "go113"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.scheduled_backups.id
  }

  source_archive_bucket = var.function_bucket
  source_archive_object = google_storage_bucket_object.scheduled_backups.name
  service_account_email = google_service_account.scheduled_backups.email

  lifecycle {
    ignore_changes = [max_instances]
  }
}
