variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "app" {
  type = object({
    name  = string
    cidrs = list(string)
  })
  default = null
}

variable "mysql" {
  type = object({
    name  = string
    cidrs = list(string)
  })
  default = null
}

variable "bastion" {
  type = object({
    name  = string
    cidrs = list(string)
  })
  default = null
}

variable "vm" {
  type = object({
    name  = string
    cidrs = list(string)
  })
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_virtual_network" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "app" {
  count                = var.app != null ? 1 : 0
  name                 = var.app.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.app.cidrs
  service_endpoints    = ["Microsoft.KeyVault"]
}

resource "azurerm_subnet" "mysql" {
  count                = var.mysql != null ? 1 : 0
  name                 = var.mysql.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.mysql.cidrs

  service_endpoints = [
    "Microsoft.KeyVault",
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

resource "azurerm_subnet" "bastion" {
  count                = var.bastion != null ? 1 : 0
  name                 = var.bastion.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.bastion.cidrs
}

resource "azurerm_subnet" "vm" {
  count                = var.vm != null ? 1 : 0
  name                 = var.vm.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.vm.cidrs
}

output "vnet" {
  value = azurerm_virtual_network.main
}

output "subnet_app" {
  value = var.app != null ? one(azurerm_subnet.app) : null
}

output "subnet_mysql" {
  value = var.mysql != null ? one(azurerm_subnet.mysql) : null
}

output "subnet_bastion" {
  value = var.bastion != null ? one(azurerm_subnet.bastion) : null
}

output "subnet_vm" {
  value = var.vm != null ? one(azurerm_subnet.vm) : null
}
