data "azurerm_key_vault_secret" "password" {
  name         = "mysql-${var.name}-password-001"
  key_vault_id = var.key_vault_id
}

resource "azurerm_private_dns_zone" "main" {
  count               = var.private_dns_zone == null ? 1 : 0
  name                = "mysql-${var.name}-001.private.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "mysql-${var.name}-001"
  private_dns_zone_name = var.private_dns_zone == null ? azurerm_private_dns_zone.main.0.name : var.private_dns_zone.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.network.vnet_id
  tags                  = var.tags
}

resource "azurerm_mysql_flexible_server" "main" {
  resource_group_name    = var.resource_group_name
  location               = var.location
  name                   = "mysql-${var.name}-001"
  administrator_login    = var.administrator_login
  administrator_password = data.azurerm_key_vault_secret.password.value
  backup_retention_days  = var.backup_retention_days
  delegated_subnet_id    = var.network.subnet_id
  private_dns_zone_id    = var.private_dns_zone == null ? azurerm_private_dns_zone.main.0.id : var.private_dns_zone.id
  sku_name               = var.sku_name
  version                = var.db_version
  zone                   = var.zone

  dynamic "high_availability" {
    for_each = var.high_availability == null ? [] : [1]
    content {
      mode                      = var.high_availability.mode
      standby_availability_zone = var.high_availability.standby_availability_zone
    }
  }

  storage {
    iops              = var.storage.iops
    size_gb           = var.storage.size_gb
    auto_grow_enabled = true
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance == null ? [] : [1]
    content {
      day_of_week  = var.maintenance.day_of_week
      start_hour   = var.maintenance.start_hour
      start_minute = var.maintenance.start_minute
    }
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.main]

  lifecycle {
    ignore_changes = [
      zone,
      high_availability.0.standby_availability_zone
    ]
  }
}

resource "azurerm_mysql_flexible_server_configuration" "main" {
  for_each            = var.parameters
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  value               = each.value
}

resource "azurerm_mysql_flexible_database" "main" {
  charset             = "utf8mb4"
  collation           = "utf8mb4_bin"
  name                = var.db_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name               = "mysql-${var.name}-logs-001"
  target_resource_id = azurerm_mysql_flexible_server.main.id

  storage_account_id         = var.diagnostics.storage_account_id
  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id

  enabled_log {
    category = "MySqlAuditLogs"
  }

  enabled_log {
    category = "MySqlSlowLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }
}
