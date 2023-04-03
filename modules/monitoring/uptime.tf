# NOTE: 通知チャンネルの設定項目が見当たらなかったので手動で Slack チャンネルに紐付けた
resource "google_monitoring_uptime_check_config" "cloudrun" {
  for_each     = var.uptimes
  project      = var.project
  display_name = "${var.name}${var.name_suffix} uptime failure"
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
