resource "google_cloud_run_service" "default" {
  name                       = var.name
  location                   = var.location
  autogenerate_revision_name = false

  metadata {
    annotations = {
      "client.knative.dev/user-image"           = var.container_image
      "run.googleapis.com/vpc-access-connector" = var.connector_name
      "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
    }
  }

  template {
    spec {
      # container_concurrency = 100
      # timeout_seconds       = 300

      containers {
        image = var.container_image

        # ports {
        #   container_port = 8080
        #   name           = "http1"
        # }

        # resources {
        #   limits = {
        #     cpu    = "1"
        #     memory = "1024Mi"
        #   }
        # }
      }
    }
  }

  # traffic {
  #   latest_revision = true
  #   percent         = 100
  # }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["run.googleapis.com/client-name"],
      metadata[0].annotations["run.googleapis.com/client-version"],
      metadata[0].annotations["run.googleapis.com/ingress"],
      metadata[0].annotations["run.googleapis.com/operation-id"],
    ]
  }
}
