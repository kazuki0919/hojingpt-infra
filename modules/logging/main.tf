variable "project" {
  type = string
}

variable "location" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 800
}

variable "name" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

resource "google_logging_project_bucket_config" "applog" {
  project          = var.project
  location         = var.location
  description      = "Application log"
  retention_days   = var.log_retention_days
  bucket_id        = "${var.name}-applog${var.name_suffix}"
  enable_analytics = true
}

resource "google_logging_project_bucket_config" "accesslog" {
  project          = var.project
  location         = var.location
  description      = "Access log"
  retention_days   = var.log_retention_days
  bucket_id        = "${var.name}-accesslog${var.name_suffix}"
  enable_analytics = true
}

resource "google_logging_project_sink" "applog" {
  name        = "${var.name}-applog${var.name_suffix}"
  destination = "logging.googleapis.com/${google_logging_project_bucket_config.applog.name}"

  filter = <<-EOT
    resource.type="cloud_run_revision" AND
    (
      log_name="projects/${var.project}/logs/run.googleapis.com%2Fstderr" OR
      log_name="projects/${var.project}/logs/run.googleapis.com%2Fstdout"
    )
  EOT

  unique_writer_identity = true
}

resource "google_logging_project_sink" "accesslog" {
  name        = "${var.name}-accesslog${var.name_suffix}"
  destination = "logging.googleapis.com/${google_logging_project_bucket_config.accesslog.name}"

  filter = <<-EOT
    resource.type="cloud_run_revision"
    log_name="projects/${var.project}/logs/run.googleapis.com%2Frequests"
  EOT

  unique_writer_identity = true
}
