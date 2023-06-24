resource "azurerm_container_registry" "main" {
  name                = var.registory_name
  resource_group_name = var.resource_group_name
  location            = var.location

  admin_enabled                 = true
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false
  export_policy_enabled         = true
  network_rule_bypass_option    = "AzureServices"
  public_network_access_enabled = true
  quarantine_policy_enabled     = false
  zone_redundancy_enabled       = false
  sku                           = "Basic"

  identity {
    identity_ids = var.user_assigned_ids
    type         = "UserAssigned"
  }

  retention_policy {
    days    = 7
    enabled = false
  }

  trust_policy {
    enabled = false
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "acr" {
  scope                = azurerm_container_registry.main.id
  principal_id         = var.key_vault_object_id
  role_definition_name = "AcrPull"
}

resource "azurerm_monitor_diagnostic_setting" "acr" {
  name               = "acr-${var.name}-logs-001"
  target_resource_id = azurerm_container_registry.main.id

  storage_account_id         = var.diagnostics.storage_account_id
  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_log {
    category_group = "audit"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }

  # HACK
  lifecycle {
    ignore_changes = [
      storage_account_id,
      log_analytics_workspace_id,
    ]
  }
}

resource "azurerm_container_app_environment" "main" {
  name                           = "cae-${var.name}-001"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.diagnostics.log_analytics_workspace_id
  infrastructure_subnet_id       = var.subnet_id
  internal_load_balancer_enabled = true
  tags                           = var.tags

  # HACK: Once created, it cannot be changed by terraform... see: https://stackoverflow.com/questions/73811960/how-can-i-modify-container-app-environment-customerid
  lifecycle {
    ignore_changes = [log_analytics_workspace_id]
  }
}

resource "azurerm_monitor_diagnostic_setting" "cae" {
  name               = "cae-${var.name}-logs-001"
  target_resource_id = azurerm_container_app_environment.main.id

  storage_account_id         = var.diagnostics.storage_account_id
  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id

  enabled_log {
    category = "ContainerAppConsoleLogs"
  }

  enabled_log {
    category = "ContainerAppSystemLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }

  # HACK
  lifecycle {
    ignore_changes = [
      storage_account_id,
      log_analytics_workspace_id,
    ]
  }
}
