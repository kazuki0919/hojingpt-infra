resource "google_monitoring_alert_policy" "error_logs" {
  display_name          = "${var.name}${var.name_suffix} error logs"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"

    notification_rate_limit {
      period = "300s"
    }
  }

  combiner = "OR"

  conditions {
    display_name = "Log match condition"

    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_run_revision" AND
        severity=ERROR
      EOT
    }
  }

  user_labels = var.labels
}

resource "google_monitoring_alert_policy" "lower_latency" {
  display_name          = "${var.name}${var.name_suffix} lower latency"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "604800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Run Revision - Request Latency"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "0s"
      threshold_value = 10000

      filter = <<-EOT
        resource.type="cloud_run_revision" AND
        metric.type="run.googleapis.com/request_latencies"
      EOT

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels
}
