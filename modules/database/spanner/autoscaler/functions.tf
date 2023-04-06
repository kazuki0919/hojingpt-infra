# Service Account
resource "google_service_account" "poller_sa" {
  account_id   = "${var.name}-spanner-poller"
  display_name = "Autoscaler - Metrics Poller Service Account"
}

resource "google_service_account" "scaler_sa" {
  account_id   = "${var.name}-spanner-scaler"
  display_name = "Autoscaler - Scaler Function Service Account"
}

# IAM
resource "google_project_iam_member" "poller_sa_spanner" {
  project = var.project
  role    = "roles/spanner.viewer"
  member  = "serviceAccount:${google_service_account.poller_sa.email}"
}

# PubSub
resource "google_pubsub_topic" "poller_topic" {
  name = "${var.name}-spanner-autoscaler-poller${var.name_suffix}"
}

resource "google_pubsub_topic_iam_member" "poller_pubsub_sub_iam" {
  project = var.project
  topic   = google_pubsub_topic.poller_topic.name
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.poller_sa.email}"
}

resource "google_pubsub_topic" "scaler_topic" {
  name = "${var.name}-spanner-autoscaler-scaler${var.name_suffix}"
}

resource "google_pubsub_topic_iam_member" "poller_pubsub_pub_iam" {
  project = var.project
  topic   = google_pubsub_topic.scaler_topic.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.poller_sa.email}"
}

resource "google_pubsub_topic_iam_member" "scaler_pubsub_sub_iam" {
  project = var.project
  topic   = google_pubsub_topic.scaler_topic.name
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.scaler_sa.email}"
}

# Firestore
resource "google_project_iam_member" "scaler_sa_firestore" {
  project = var.project
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.scaler_sa.email}"
}

data "archive_file" "local_poller_source" {
  type        = "zip"
  source_dir  = abspath("${path.module}/src/poller/poller-core")
  output_path = "${path.module}/bin/poller.zip"
}

resource "google_storage_bucket_object" "gcs_functions_poller_source" {
  name   = "poller.${data.archive_file.local_poller_source.output_md5}.zip"
  bucket = var.function_bucket
  source = data.archive_file.local_poller_source.output_path
}

data "archive_file" "local_scaler_source" {
  type        = "zip"
  source_dir  = abspath("${path.module}/src/scaler/scaler-core")
  output_path = "${path.module}/bin/scaler.zip"
}

resource "google_storage_bucket_object" "gcs_functions_scaler_source" {
  name   = "scaler.${data.archive_file.local_scaler_source.output_md5}.zip"
  bucket = var.function_bucket
  source = data.archive_file.local_scaler_source.output_path
}

resource "google_cloudfunctions_function" "poller_function" {
  name                = "${var.name}-spanner-autoscaler-poller${var.name_suffix}"
  project             = var.project
  region              = var.region
  ingress_settings    = "ALLOW_INTERNAL_AND_GCLB"
  available_memory_mb = 512
  entry_point         = "checkSpannerScaleMetricsPubSub"
  runtime             = "nodejs10"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.poller_topic.id
  }

  source_archive_bucket = var.function_bucket
  source_archive_object = google_storage_bucket_object.gcs_functions_poller_source.name
  service_account_email = google_service_account.poller_sa.email

  lifecycle {
    ignore_changes = [max_instances]
  }
}

resource "google_cloudfunctions_function" "scaler_function" {
  name                = "${var.name}-spanner-autoscaler-scaler${var.name_suffix}"
  project             = var.project
  region              = var.region
  ingress_settings    = "ALLOW_INTERNAL_AND_GCLB"
  available_memory_mb = 512
  entry_point         = "scaleSpannerInstancePubSub"
  runtime             = "nodejs10"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.scaler_topic.id
  }

  source_archive_bucket = var.function_bucket
  source_archive_object = google_storage_bucket_object.gcs_functions_scaler_source.name
  service_account_email = google_service_account.scaler_sa.email

  lifecycle {
    ignore_changes = [max_instances]
  }
}
