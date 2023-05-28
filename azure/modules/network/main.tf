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
    cidrs = list(string)
  })
}

variable "mysql" {
  type = object({
    cidrs = list(string)
  })
}

variable "bastion" {
  type = object({
    cidrs     = list(string)
    allow_ips = list(string)
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.name}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

#
# Container Apps
#
resource "azurerm_subnet" "app" {
  count                = var.app != null ? 1 : 0
  name                 = "snet-${var.name}-001"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.app.cidrs

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Storage",
  ]
}

resource "azurerm_network_security_group" "app" {
  count               = var.app != null ? 1 : 0
  name                = "nsg-${var.name}-http-redis-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "6380"
    direction                  = "Inbound"
    name                       = "AllowRedisBound"
    priority                   = 100
    protocol                   = "*"

    source_address_prefixes = concat(
      var.app.cidrs,
      var.bastion.cidrs,
    )

    source_port_range = "*"
  }

  security_rule {
    access                     = "Deny"
    destination_address_prefix = "*"
    destination_port_range     = "6380"
    direction                  = "Inbound"
    name                       = "DenyRedisInbound"
    priority                   = 110
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }

  tags = var.tags
}

#
# MySQL
#
resource "azurerm_subnet" "mysql" {
  count                = var.mysql != null ? 1 : 0
  name                 = "snet-${var.name}-002"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.mysql.cidrs

  service_endpoints = [
    "Microsoft.KeyVault",
  ]

  delegation {
    name = "Microsoft.DBforMySQL.flexibleServers"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "mysql" {
  count               = var.mysql != null ? 1 : 0
  name                = "nsg-${var.name}-mysql-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "3306"
    direction                  = "Inbound"
    name                       = "AllowCidrBlockMySQLInbound"
    priority                   = 100
    protocol                   = "Tcp"

    source_address_prefixes = concat(
      var.app.cidrs,
      var.bastion.cidrs
    )

    source_port_range = "*"
  }

  security_rule {
    access                     = "Deny"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "*"
    direction                  = "Inbound"
    name                       = "DenyTagCustomAnyInbound"
    priority                   = 110
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }

  tags = var.tags
}

#
# Bastion
#
resource "azurerm_subnet" "bastion" {
  count                = var.bastion != null ? 1 : 0
  name                 = "snet-${var.name}-003"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.bastion.cidrs
}

resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-${var.name}-bastion-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    direction                  = "Inbound"
    name                       = "SSH"
    priority                   = 1000
    protocol                   = "Tcp"
    source_address_prefixes    = var.bastion.allow_ips
    source_port_range          = "*"
  }

  tags = var.tags
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
