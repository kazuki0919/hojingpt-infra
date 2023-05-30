data "azurerm_key_vault_secret" "password" {
  name         = "mysql-${var.name}-password-001"
  key_vault_id = var.key_vault_id
}

resource "azurerm_private_dns_zone" "main" {
  name                = "mysql-${var.name}.private.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "mysql-${var.name}-001"
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.network.vnet_id
  tags                  = var.tags
}

resource "azurerm_mysql_flexible_server" "main" {
  resource_group_name          = var.resource_group_name
  location                     = var.location
  name                         = "mysql-${var.name}-001"
  administrator_login          = var.administrator_login
  administrator_password       = data.azurerm_key_vault_secret.password.value
  backup_retention_days        = var.backup_retention_days
  delegated_subnet_id          = var.network.subnet_id
  geo_redundant_backup_enabled = false
  private_dns_zone_id          = azurerm_private_dns_zone.main.id
  sku_name                     = var.sku_name
  version                      = var.db_version
  zone                         = var.zone

  #TODO
  # high_availability {
  #   mode                      = "ZoneRedundant"
  #   standby_availability_zone = "2"
  # }

  # maintenance_window {
  #   day_of_week  = 0
  #   start_hour   = 8
  #   start_minute = 0
  # }

  storage {
    iops    = var.storage.iops
    size_gb = var.storage.size_gb
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.main]
}

resource "azurerm_mysql_flexible_server_configuration" "main" {
  for_each = {
    # interactive_timeout = "600"
  }
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
