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

resource "google_service_account" "system_event_notifier" {
  account_id   = "${var.name}-sysevent${var.name_suffix}"
  display_name = "System event notifier by Cloud Functions"
}

data "archive_file" "system_event_notifier" {
  type        = "zip"
  source_dir  = abspath("${path.module}/src")
  output_path = "${path.module}/bin/system_event_notifier.zip"
}

resource "google_storage_bucket_object" "system_event_notifier" {
  name   = "system_event_notifier.${data.archive_file.system_event_notifier.output_md5}.zip"
  bucket = var.function_bucket
  source = data.archive_file.system_event_notifier.output_path
}

resource "google_cloudfunctions2_function" "system_event_notifier" {
  name     = "${var.name}-system-event-notifier${var.name_suffix}"
  location = var.location
  project  = var.project

  build_config {
    runtime     = "nodejs18"
    entry_point = "main"

    source {
      storage_source {
        bucket = var.function_bucket
        object = google_storage_bucket_object.system_event_notifier.name
      }
    }
  }

  service_config {
    min_instance_count             = 1
    max_instance_count             = 2
    available_memory               = "256M"
    timeout_seconds                = 60
    ingress_settings               = "ALLOW_INTERNAL_AND_GCLB"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.system_event_notifier.email
  }



  # event_trigger {
  #   trigger_region        = var.region
  #   event_type            = "google.cloud.audit.log.v1.written"
  #   retry_policy          = "RETRY_POLICY_RETRY"
  #   service_account_email = google_service_account.system_event_notifier.email
  # }

  lifecycle {
    ignore_changes = [service_config[0].max_instance_count]
  }
}
