#################################################################################
# Azure Monitor Action Group
#################################################################################
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

#################################################################################
# Azure Monitor Alert: ContainerApps
#################################################################################
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

#################################################################################
# Azure Monitor Alert: MySQL
#################################################################################
resource "azurerm_monitor_metric_alert" "mysql_cpu" {
  for_each            = var.mysql
  name                = "alert-${each.key}-cpu"
  description         = "[WARN] MySQL CPU usage exceeded 70%. target: ${each.key}"
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
  description         = "[WARN] MySQL Memory usage exceeded 70%. target: ${each.key}"
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
  description         = "[WARN] MySQL Disk usage exceeded 70%. target: ${each.key}"
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
  description         = "[WARN] MySQL I/O usage exceeded 70%. target: ${each.key}"
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
  description         = "[WARN] MySQL Log storage usage exceeded 70%. target: ${each.key}"
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

#################################################################################
# Azure Monitor Alert: Redis
#################################################################################
resource "azurerm_monitor_metric_alert" "cpu" {
  for_each            = var.redis
  name                = "alert-${each.key}-cpu"
  description         = "[WARN] Redis CPU usage exceeded 70%. target: ${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = 70
    metric_namespace = "microsoft.cache/redis"
    metric_name      = "percentProcessorTime"
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

resource "azurerm_monitor_metric_alert" "mem" {
  for_each            = var.redis
  name                = "alert-${each.key}-mem"
  description         = "[WARN] Redis Memory usage exceeded 70%. target: ${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = 70
    metric_namespace = "microsoft.cache/redis"
    metric_name      = "usedmemorypercentage"
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

#################################################################################
# Azure Monitor Alert: FrontDoor
#################################################################################
resource "azurerm_monitor_metric_alert" "frontdoor_errors" {
  for_each            = var.frontdoor
  name                = "alert-${each.key}-errors"
  description         = "[CRITICAL] FrontDoor 5xx rate exceeded 70%. target: ${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  severity            = 0
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    threshold        = 70
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "Percentage5XX"
    operator         = "GreaterThan"
    aggregation      = "Average"

    dimension {
      name     = "Endpoint"
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

#################################################################################
# Application Insights
#################################################################################
resource "azurerm_application_insights" "web" {
  name                = "aai-${var.name}-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.diagnostics.log_analytics_workspace_id
  retention_in_days   = 30
}

resource "azurerm_application_insights_standard_web_test" "main" {
  for_each                = var.webtest
  name                    = "test-${each.key}"
  resource_group_name     = var.resource_group_name
  location                = var.location
  application_insights_id = azurerm_application_insights.web.id
  retry_enabled           = true
  enabled                 = true
  timeout                 = 30

  geo_locations = [
    "us-va-ash-azr",
    "us-ca-sjc-azr",
    "apac-jp-kaw-edge",
    "emea-gb-db3-azr",
    "emea-nl-ams-azr",
  ]

  request {
    url                              = each.value
    parse_dependent_requests_enabled = false
  }

  validation_rules {
    expected_status_code        = 200
    ssl_cert_remaining_lifetime = 7
    ssl_check_enabled           = true
  }

  lifecycle {
    ignore_changes = [
      tags,
      enabled,
    ]
  }
}

resource "azurerm_monitor_metric_alert" "webtest" {
  for_each            = var.webtest
  name                = "alert-${each.key}-webtest"
  description         = "[CRITICAL] Service Down. target: ${each.value}"
  resource_group_name = var.resource_group_name
  scopes              = [
    azurerm_application_insights.web.id,
    azurerm_application_insights_standard_web_test.main[each.key].id,
  ]
  severity            = 0
  frequency           = "PT5M"
  window_size         = "PT15M"

  application_insights_web_test_location_availability_criteria {
    component_id          = azurerm_application_insights.web.id
    web_test_id           = azurerm_application_insights_standard_web_test.main[each.key].id
    failed_location_count = 2
  }

  action {
    action_group_id = azurerm_monitor_action_group.metrics.id
  }

  lifecycle {
    ignore_changes = [enabled]
  }
}
