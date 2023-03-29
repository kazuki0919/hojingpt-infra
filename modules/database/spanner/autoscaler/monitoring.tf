variable "monitoring_enabled" {
  type    = bool
  default = false
}

resource "google_monitoring_dashboard" "dashboard" {
  count   = var.monitoring_enabled ? 1 : 0
  project = var.project

  dashboard_json = templatefile("${path.module}/monitoring.dashboard.json.tftpl", {
    thresholds_high_priority_cpu_percentage = 0.65
    thresholds_rolling_24hr_cpu_percentage  = 0.9
    thresholds_storage_percentage           = 0.75
  })
}
