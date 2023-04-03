#
# Cloud Run
#
resource "google_monitoring_alert_policy" "cloudrun_error_logs" {
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

resource "google_monitoring_alert_policy" "cloudrun_latency" {
  display_name          = "${var.name}${var.name_suffix} lower latency"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Run Revision - Request Latency"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "300s"
      threshold_value = 10000

      filter = <<-EOT
        resource.type="cloud_run_revision" AND
        metric.type="run.googleapis.com/request_latencies"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
        group_by_fields      = ["resource.label.service_name"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels
}

resource "google_monitoring_alert_policy" "cloudrun_cpu" {
  display_name          = "${var.name}${var.name_suffix} high cpu usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Run Revision - Container CPU Utilization"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "0s"
      threshold_value = 0.7

      filter = <<-EOT
        resource.type="cloud_run_revision" AND
        metric.type="run.googleapis.com/container/cpu/utilizations"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
        group_by_fields      = ["resource.label.service_name"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels
}

resource "google_monitoring_alert_policy" "cloudrun_memory" {
  display_name          = "${var.name}${var.name_suffix} high memory usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Run Revision - Container Memory Utilization"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "300s"
      threshold_value = 0.7

      filter = <<-EOT
        resource.type="cloud_run_revision" AND
        metric.type="run.googleapis.com/container/memory/utilizations"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_PERCENTILE_99"
        group_by_fields      = ["resource.label.service_name"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels
}

#
# Redis
#
# resource "google_monitoring_alert_policy" "redis_cpu" {
#   display_name          = "${var.name}${var.name_suffix} high memory usage"
#   notification_channels = [var.emergency_channel]

#   alert_strategy {
#     auto_close = "1800s"
#   }

#   combiner = "OR"

#   conditions {
#     display_name = "Cloud Run Revision - Container Memory Utilization"

#     condition_threshold {
#       comparison      = "COMPARISON_GT"
#       duration        = "300s"
#       threshold_value = 0.7

#       filter = <<-EOT
#         resource.type="cloud_run_revision" AND
#         metric.type="run.googleapis.com/container/memory/utilizations"
#       EOT

#       aggregations {
#         alignment_period     = "300s"
#         per_series_aligner   = "ALIGN_PERCENTILE_99"
#         cross_series_reducer = "REDUCE_PERCENTILE_99"
#         group_by_fields      = ["resource.label.service_name"]
#       }

#       trigger {
#         count   = 1
#         percent = 0
#       }
#     }
#   }

#   user_labels = var.labels
# }
