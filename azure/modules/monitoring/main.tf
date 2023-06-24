variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "container_apps" {
  type = map(object({
    max_cpu = optional(number, 10)
    max_mem = optional(number, 2)
  }))
}

variable "mysql" {
  type    = map(string)
  default = {}
}

variable "redis" {
  type    = map(string)
  default = {}
}

variable "logicapp_metrics" {
  type = object({
    name         = string
    callback_url = string
  })
}

variable "diagnostics" {
  type = object({
    storage_account_id         = string
    log_analytics_workspace_id = string
  })
}

data "azurerm_logic_app_workflow" "metrics" {
  name                = var.logicapp_metrics.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_monitor_action_group" "metrics" {
  name                = "mag-${var.name}-metrics-alert"
  resource_group_name = var.resource_group_name
  short_name          = "MetricsAlert"

  logic_app_receiver {
    callback_url            = var.logicapp_metrics.callback_url
    name                    = "MetricsAlert"
    resource_id             = data.azurerm_logic_app_workflow.metrics.id
    use_common_alert_schema = true
  }
}

variable "logicapp_applogs" {
  type = object({
    name         = string
    callback_url = string
  })
}

data "azurerm_logic_app_workflow" "applogs" {
  name                = var.logicapp_applogs.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_monitor_action_group" "applogs" {
  name                = "mag-${var.name}-applogs-alert"
  resource_group_name = var.resource_group_name
  short_name          = "AppLogsAlert"

  logic_app_receiver {
    callback_url            = var.logicapp_applogs.callback_url
    name                    = "AppLogsAlert"
    resource_id             = data.azurerm_logic_app_workflow.applogs.id
    use_common_alert_schema = true
  }
}

data "azurerm_container_app" "main" {
  for_each            = var.container_apps
  name                = each.key
  resource_group_name = var.resource_group_name
}

resource "azurerm_monitor_metric_alert" "containerapp_cpu" {
  for_each            = var.container_apps
  name                = "alert-${each.key}-cpu"
  description         = "[WARN] ContainerApps CPU usage exceeded 70%. target:${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_container_app.main[each.key].id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = each.value.max_cpu * 1024 * 1024 * 1024 * 0.7
    metric_namespace = "microsoft.app/containerapps"
    metric_name      = "UsageNanoCores"
    operator         = "GreaterThan"
    aggregation      = "Average"

    dimension {
      name     = "revisionName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.metrics.id
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "azurerm_monitor_metric_alert" "containerapp_mem" {
  for_each            = var.container_apps
  name                = "alert-${each.key}-mem"
  description         = "[WARN] ContainerApps Memory usage exceeded 70%. target:${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_container_app.main[each.key].id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = each.value.max_mem * 1024 * 1024 * 1024 * 0.7
    metric_namespace = "microsoft.app/containerapps"
    metric_name      = "WorkingSetBytes"
    operator         = "GreaterThan"
    aggregation      = "Average"

    dimension {
      name     = "revisionName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.metrics.id
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "azurerm_monitor_metric_alert" "containerapp_5xx" {
  name                = "alert-ca-${var.name}-5xx"
  description         = "[ERROR] ContainerApps 5xx detected"
  resource_group_name = var.resource_group_name
  scopes              = [for app in data.azurerm_container_app.main : app.id]
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = 1
    metric_namespace = "microsoft.app/containerapps"
    metric_name      = "Requests"
    operator         = "GreaterThan"
    aggregation      = "Total"

    dimension {
      name     = "statusCodeCategory"
      operator = "Include"
      values   = ["5xx"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.metrics.id
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "containerapp_errors" {
  name                    = "alert-ca-${var.name}-errors"
  description             = "[ERROR] ContainerApps error log detected"
  resource_group_name     = var.resource_group_name
  location                = var.location
  scopes                  = [var.diagnostics.log_analytics_workspace_id]
  evaluation_frequency    = "PT5M"
  window_duration         = "PT15M"
  severity                = 1
  auto_mitigation_enabled = true
  target_resource_types   = ["Microsoft.OperationalInsights/workspaces"]

  criteria {
    query = <<-EOT
      ContainerAppConsoleLogs_CL
      | where TimeGenerated >= now(-5m)
      | where Log_s has_cs "ERROR"
      | project TimeGenerated, RevisionName_s, Log_s
    EOT

    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThanOrEqual"

    dimension {
      name     = "RevisionName_s"
      operator = "Include"
      values   = ["*"]
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 3
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.applogs.id]
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "azurerm_monitor_metric_alert" "mysql_cpu" {
  for_each            = var.mysql
  name                = "alert-${each.key}-cpu"
  description         = "[WARN] MySQL CPU usage exceeded 70%"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = 70
    metric_namespace = "microsoft.dbformysql/flexibleservers"
    metric_name      = "cpu_percent"
    operator         = "GreaterThan"
    aggregation      = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.metrics.id
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "azurerm_monitor_metric_alert" "mysql_mem" {
  for_each            = var.mysql
  name                = "alert-${each.key}-mem"
  description         = "[WARN] MySQL Memory usage exceeded 70%"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = 70
    metric_namespace = "microsoft.dbformysql/flexibleservers"
    metric_name      = "memory_percent"
    operator         = "GreaterThan"
    aggregation      = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.metrics.id
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "azurerm_monitor_metric_alert" "mysql_disk" {
  for_each            = var.mysql
  name                = "alert-${each.key}-disk"
  description         = "[WARN] MySQL Disk usage exceeded 70%"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = 70
    metric_namespace = "microsoft.dbformysql/flexibleservers"
    metric_name      = "storage_percent"
    operator         = "GreaterThan"
    aggregation      = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.metrics.id
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "azurerm_monitor_metric_alert" "mysql_io" {
  for_each            = var.mysql
  name                = "alert-${each.key}-io"
  description         = "[WARN] MySQL I/O usage exceeded 70%"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = 70
    metric_namespace = "microsoft.dbformysql/flexibleservers"
    metric_name      = "io_consumption_percent"
    operator         = "GreaterThan"
    aggregation      = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.metrics.id
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}

resource "azurerm_monitor_metric_alert" "mysql_log" {
  for_each            = var.mysql
  name                = "alert-${each.key}-log"
  description         = "[WARN] MySQL Log storage usage exceeded 70%"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = 70
    metric_namespace = "microsoft.dbformysql/flexibleservers"
    metric_name      = "serverlog_storage_percent"
    operator         = "GreaterThan"
    aggregation      = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.metrics.id
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}
