###########################################################################################
# NOTES
#  - Doing this will determine the location of the project.
#  - This primarily affects Firestore and others. The location cannot be changed later.
#  - For this reason, we have decided to exclude it in terraform.
###########################################################################################
# resource "google_app_engine_application" "default" {
#   project     = var.project
#   location_id = var.location
# }

resource "google_cloud_scheduler_job" "poller_job" {
  name        = "${var.name}-spanner-autoscaler-poll-metrics${var.name_suffix}"
  description = "Poll metrics for main instance"
  schedule    = "*/2 * * * *"
  time_zone   = "Asia/Tokyo"

  pubsub_target {
    topic_name = google_pubsub_topic.poller_topic.id

    data = base64encode(jsonencode(
      [
        {
          "projectId" : "${var.project}",
          "instanceId" : "${var.spanner_name}",
          "scalerPubSubTopic" : "${google_pubsub_topic.scaler_topic.id}",
          "units" : "PROCESSING_UNITS",
          "minSize" : var.min_size,
          "maxSize" : var.max_size,
          "scalingMethod" : "LINEAR",
          "stateDatabase" : {
            "name" : "firestore",
          }
        }
    ]))
  }

  # depends_on = [google_app_engine_application.default]
}
