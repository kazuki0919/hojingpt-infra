resource "azurerm_subnet" "mysql" {
  name                 = var.subnet_mysql.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_mysql.cidrs

  service_endpoints = [
    "Microsoft.KeyVault",
  ]

  delegation {
    name = "Microsoft.DBforMySQL.flexibleServers"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }

  private_link_service_network_policies_enabled = true
  private_endpoint_network_policies_enabled     = false
}

resource "azurerm_network_security_group" "mysql" {
  name                = "nsg-${var.name}-mysql-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    direction                  = "Inbound"
    priority                   = 100
    name                       = "AllowCidrBlockMySQLInbound"
    destination_port_range     = "3306"
    protocol                   = "Tcp"
    source_address_prefixes    = var.subnet_app.cidrs
    source_port_range          = "*"
    destination_address_prefix = "*"
    access                     = "Allow"
  }

  security_rule {
    direction                  = "Inbound"
    priority                   = 110
    name                       = "DenyTagCustomAnyInbound"
    destination_port_range     = "*"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Deny"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "mysql" {
  subnet_id                 = azurerm_subnet.mysql.id
  network_security_group_id = azurerm_network_security_group.mysql.id
}
