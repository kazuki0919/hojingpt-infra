variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "alias_name" {
  type = string
}

variable "network" {
  type = object({
    name  = string
    id    = string
    cidrs = list(string)
  })
}

variable "dns_vnet_link_name" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "db_version" {
  type = string
}

variable "db_name" {
  type = string
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "zone" {
  type    = string
  default = "1"
}


variable "storage" {
  type = object({
    iops    = number
    size_gb = number
  })
}

resource "azurerm_subnet" "main" {
  address_prefixes     = var.network.cidrs
  name                 = "snet-${var.name}-002"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.network.name

  service_endpoints = [
    "Microsoft.KeyVault",
    # "Microsoft.Storage",
  ]

  delegation {
    name = "dlg-Microsoft.DBforMySQL-flexibleServers"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "main" {
  name                = "mysql-${var.alias_name}.private.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = var.dns_vnet_link_name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.network.id
}

resource "azurerm_mysql_flexible_server" "main" {
  resource_group_name          = var.resource_group_name
  location                     = var.location
  name                         = "mysql-${var.alias_name}"
  backup_retention_days        = var.backup_retention_days
  delegated_subnet_id          = azurerm_subnet.main.id
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

  depends_on = [azurerm_private_dns_zone_virtual_network_link.main]
}

#TODO
# resource "azurerm_mysql_flexible_database" "main" {
#   charset             = "utf8mb4"
#   collation           = "utf8mb4_bin"
#   name                = var.db_name
#   resource_group_name = var.resource_group_name
#   server_name         = azurerm_mysql_flexible_server.main.name
# }
