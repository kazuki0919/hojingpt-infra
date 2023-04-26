resource "google_monitoring_uptime_check_config" "cloudrun" {
  for_each     = var.uptimes
  project      = var.project
  display_name = "${var.name}${var.name_suffix} cloudrun uptime failure"
  timeout      = "10s"
  period       = "300s"

  http_check {
    path           = each.value.path
    port           = "443"
    request_method = "GET"
    use_ssl        = true

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
      status_value = 0
    }
  }

  monitored_resource {
    type = "cloud_run_revision"
    labels = {
      project_id         = var.project
      location           = each.value.location
      service_name       = each.value.service_name
      configuration_name = ""
      revision_name      = ""
    }
  }

  checker_type = "STATIC_IP_CHECKERS"
}

resource "google_monitoring_alert_policy" "cloudrun_uptime" {
  for_each              = google_monitoring_uptime_check_config.cloudrun
  display_name          = "${var.name}${var.name_suffix} cloudrun uptime failure"
  notification_channels = [var.emergency_channel]

  # alert_strategy {
  #   auto_close = "1800s"
  # }

  combiner = "OR"

  conditions {
    display_name = "Failure of uptime check_id ${each.value.uptime_check_id}"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "60s"
      threshold_value = 1

      filter = <<-EOT
        metric.type="monitoring.googleapis.com/uptime_check/check_passed" AND
        metric.label.check_id="${each.value.uptime_check_id}" AND
        resource.type="cloud_run_revision"
      EOT

      aggregations {
        alignment_period     = "1200s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.*"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels
}
