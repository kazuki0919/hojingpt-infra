# Allows poller to get Spanner metrics
resource "google_project_iam_member" "poller_get_metrics_iam" {
  role    = "roles/monitoring.viewer"
  project = var.project
  member  = "serviceAccount:${google_service_account.poller_sa.email}"
}

resource "google_spanner_instance_iam_member" "poller_get_metadata_iam" {
  instance = var.spanner_name
  role     = "roles/spanner.viewer"
  project  = var.project
  member   = "serviceAccount:${google_service_account.poller_sa.email}"
}

# Limited role
resource "google_project_iam_custom_role" "capacity_manager_iam_role" {
  role_id     = "spannerAutoscalerCapacityManager"
  title       = "Spanner Autoscaler Capacity Manager Role"
  description = "Allows a principal to scale spanner instances"
  permissions = [
    "spanner.instanceOperations.get",
    "spanner.instances.update",
  ]
}

# Allows scaler to modify the capacity (nodes or PUs) of the Spanner instance
resource "google_spanner_instance_iam_member" "scaler_update_capacity_iam" {
  instance = var.spanner_name
  role     = google_project_iam_custom_role.capacity_manager_iam_role.name
  project  = var.project
  member   = "serviceAccount:${google_service_account.scaler_sa.email}"
}
