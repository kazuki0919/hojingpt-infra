variable "name" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "project" {
  type = string
}

variable "location" {
  type = string
}

variable "function_bucket" {
  type = string
}

data "google_project" "default" {
  project_id = var.project
}

resource "google_service_account" "default" {
  account_id   = "${var.name}-notice${var.name_suffix}"
  display_name = "System event notifier by Cloud Functions"
}

resource "google_project_iam_member" "default" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.default.email}"
}

resource "google_pubsub_topic" "default" {
  name = "${var.name}-notice${var.name_suffix}"
}

resource "google_pubsub_topic_iam_binding" "publisher" {
  project = var.project
  topic   = google_pubsub_topic.default.name
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:service-${data.google_project.default.number}@gcp-sa-monitoring-notification.iam.gserviceaccount.com"
  ]
}

resource "google_logging_project_sink" "default" {
  name        = "${var.name}-notice${var.name_suffix}"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.default.id}"

  filter = <<-EOT
    (
      resource.type="cloud_run_revision" AND
      log_name="projects/${var.project}/logs/cloudaudit.googleapis.com%2Fsystem_event"
    )
    OR
    (
      resource.type="redis_instance"
    )
    OR
    (
      resource.type="spanner_instance"
    )
  EOT

  unique_writer_identity = true
}

data "archive_file" "default" {
  type        = "zip"
  source_dir  = abspath("${path.module}/src")
  output_path = "${path.module}/bin/notice.zip"
}

resource "google_storage_bucket_object" "default" {
  name   = "notice.${data.archive_file.default.output_md5}.zip"
  bucket = var.function_bucket
  source = data.archive_file.default.output_path
}

resource "google_cloudfunctions2_function" "default" {
  name     = "${var.name}-notice${var.name_suffix}"
  location = var.location
  project  = var.project

  build_config {
    runtime     = "nodejs18"
    entry_point = "main"

    source {
      storage_source {
        bucket = var.function_bucket
        object = google_storage_bucket_object.default.name
      }
    }
  }

  service_config {
    min_instance_count             = 0
    max_instance_count             = 2
    available_memory               = "256Mi"
    timeout_seconds                = 60
    ingress_settings               = "ALLOW_INTERNAL_AND_GCLB"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.default.email
  }

  event_trigger {
    trigger_region        = var.location
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.default.id
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = google_service_account.default.email
  }

  lifecycle {
    ignore_changes = [service_config[0].max_instance_count]
  }
}
