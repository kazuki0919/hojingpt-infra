variable "name" {
  type = string
}

variable "project" {
  type = string
}

variable "location" {
  type = string
}

data "google_cloud_run_service" "app" {
  name     = var.name
  project  = var.project
  location = var.location
}

output "max_size" {
  value = tonumber(data.google_cloud_run_service.app.template[0].metadata[0].annotations["autoscaling.knative.dev/maxScale"])
}

output "max_concurrency" {
  value = data.google_cloud_run_service.app.template[0].spec[0].container_concurrency
}
