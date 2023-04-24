######################################################################################
# Cloud Run
######################################################################################
resource "google_monitoring_alert_policy" "cloudrun_error_logs" {
  for_each              = { for x in var.logs.cloudrun : x.service_name => x }
  display_name          = "${var.name}${var.name_suffix} cloudrun error logs"
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
        resource.labels.service_name="${each.key}" AND
        severity=ERROR
      EOT
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "cloudrun_lower_latency" {
  display_name          = "${var.name}${var.name_suffix} cloudrun lower latency"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Run Revision - Request Latency"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 10000
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

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

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "cloudrun_high_cpu_usage" {
  display_name          = "${var.name}${var.name_suffix} cloudrun high cpu usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Run Revision - Container CPU Utilization"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

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

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "cloudrun_high_memory_usage" {
  display_name          = "${var.name}${var.name_suffix} cloudrun high memory usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Run Revision - Container Memory Utilization"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

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

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "cloudrun_high_instances" {
  display_name          = "${var.name}${var.name_suffix} cloudrun too many instances"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Run Revision - Instance Count"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = var.cloudrun.max_size * 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="cloud_run_revision" AND
        metric.type="run.googleapis.com/container/instance_count" AND
        metric.labels.state="active"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_MAX"
        group_by_fields      = ["resource.label.service_name"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "cloudrun_high_concurrency" {
  display_name          = "${var.name}${var.name_suffix} cloudrun high concurrency"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Run Revision - Max Concurrent Requests"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = var.cloudrun.max_concurrency * 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="cloud_run_revision" AND
        metric.type="run.googleapis.com/container/max_request_concurrencies" AND
        metric.labels.state="active"
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

  lifecycle {
    ignore_changes = [enabled]
  }
}

######################################################################################
# Redis
######################################################################################
resource "google_monitoring_alert_policy" "redis_high_memory_usage" {
  display_name          = "${var.name}${var.name_suffix} redis high memory usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Memorystore Redis Instance - Memory Usage Ratio"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 70
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="redis_instance" AND
        metric.type="redis.googleapis.com/stats/memory/usage_ratio"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields = [
          "metric.label.role",
          "resource.label.node_id",
        ]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "redis_key_eviction" {
  display_name          = "${var.name}${var.name_suffix} redis key eviction"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Memorystore Redis Instance - Evicted Keys"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="redis_instance" AND
        metric.type="redis.googleapis.com/stats/evicted_keys"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = [
          "metric.label.role",
          "resource.label.node_id",
        ]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

######################################################################################
# MySQL
######################################################################################
resource "google_monitoring_alert_policy" "mysql_high_cpu_usage" {
  display_name          = "${var.name}${var.name_suffix} mysql high cpu usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud SQL Database - CPU utilization"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="cloudsql_database" AND
        metric.type="cloudsql.googleapis.com/database/cpu/utilization"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["metadata.system_labels.name"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "mysql_high_memory_usage" {
  display_name          = "${var.name}${var.name_suffix} mysql high memory usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud SQL Database - Memory utilization"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="cloudsql_database" AND
        metric.type="cloudsql.googleapis.com/database/memory/utilization"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["metadata.system_labels.name"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "mysql_high_disk_usage" {
  display_name          = "${var.name}${var.name_suffix} mysql high disk usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud SQL Database - Disk utilization"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="cloudsql_database" AND
        metric.type="cloudsql.googleapis.com/database/disk/utilization"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["metadata.system_labels.name"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "mysql_slow_query" {
  display_name          = "${var.name}${var.name_suffix} mysql slow query"
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
        resource.type="cloudsql_database"
        log_name="projects/${var.project}/logs/cloudsql.googleapis.com%2Fmysql-slow.log"
      EOT
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

######################################################################################
# Spanner
######################################################################################
# see: https://cloud.google.com/spanner/docs/monitoring-cloud?hl=ja#24-hour-rolling-average-cpu
resource "google_monitoring_alert_policy" "spanner_high_cpu_usage" {
  display_name          = "${var.name}${var.name_suffix} spanner high cpu usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Spanner Instance - CPU utilization by priority"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0.65
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="spanner_instance" AND
        metric.type="spanner.googleapis.com/instance/cpu/utilization_by_priority" AND
        metric.labels.priority="high"
      EOT

      aggregations {
        alignment_period     = "120s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.label.instance_id"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "spanner_high_processing_unit_usage" {
  display_name          = "${var.name}${var.name_suffix} spanner high processing unit usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Spanner Instance - Processing units"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = var.spanner.max_size * 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="spanner_instance" AND
        metric.type="spanner.googleapis.com/instance/processing_units"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_MAX"
        group_by_fields      = ["resource.label.instance_id"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "spanner_high_storage_usage" {
  display_name          = "${var.name}${var.name_suffix} spanner high storage usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Spanner Instance - Storage utilization"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="spanner_instance" AND
        metric.type="spanner.googleapis.com/instance/storage/utilization"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_MAX"
        group_by_fields      = ["resource.label.instance_id"]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}


######################################################################################
# VPC Access Connector
######################################################################################
resource "google_monitoring_alert_policy" "vpc_connector_high_cpu_usage" {
  display_name          = "${var.name}${var.name_suffix} vpc connector high cpu usage"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "VPC Access Connector - CPU Utilizations"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0.7
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="vpc_access_connector" AND
        metric.type="vpcaccess.googleapis.com/connector/cpu/utilizations"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_PERCENTILE_99"

        group_by_fields = [
          "resource.label.connector_name",
        ]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "vpc_connector_high_bytes_received" {
  display_name          = "${var.name}${var.name_suffix} vpc connector too many bytes received"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "VPC Access Connector - Bytes received delta"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 83886080 # 80MiB
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="vpc_access_connector" AND
        metric.type="vpcaccess.googleapis.com/connector/received_bytes_count"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"

        group_by_fields = [
          "resource.label.connector_name",
        ]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "google_monitoring_alert_policy" "vpc_connector_high_bytes_sent" {
  display_name          = "${var.name}${var.name_suffix} vpc connector too many bytes sent"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "VPC Access Connector - Bytes sent delta"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 83886080 # 80MiB
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type="vpc_access_connector" AND
        metric.type="vpcaccess.googleapis.com/connector/sent_bytes_count"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"

        group_by_fields = [
          "resource.label.connector_name",
        ]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

######################################################################################
# Function
######################################################################################
resource "google_monitoring_alert_policy" "function_failure" {
  display_name          = "${var.name}${var.name_suffix} function failure"
  notification_channels = [var.emergency_channel]

  alert_strategy {
    auto_close = "1800s"
  }

  combiner = "OR"

  conditions {
    display_name = "Cloud Function - Executions"

    condition_threshold {
      comparison              = "COMPARISON_GT"
      duration                = "300s"
      threshold_value         = 0
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = <<-EOT
        resource.type = "cloud_function" AND
        metric.type = "cloudfunctions.googleapis.com/function/execution_count" AND
        metric.labels.status != "ok"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"

        group_by_fields = [
          "metric.label.status",
          "resource.label.function_name",
        ]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }

  user_labels = var.labels

  lifecycle {
    ignore_changes = [enabled]
  }
}

# TODO: Enable if need
# resource "google_monitoring_alert_policy" "function_error_logs" {
#   display_name          = "${var.name}${var.name_suffix} function error logs"
#   notification_channels = [var.emergency_channel]

#   alert_strategy {
#     auto_close = "1800s"
#     notification_rate_limit {
#       period = "300s"
#     }
#   }

#   combiner = "OR"

#   conditions {
#     display_name = "Log match condition"

#     condition_matched_log {
#       filter = <<-EOT
#         resource.type="cloud_function"
#         severity=ERROR
#       EOT
#     }
#   }

#   user_labels = var.labels

#   lifecycle {
#     ignore_changes = [enabled]
#   }
# }
