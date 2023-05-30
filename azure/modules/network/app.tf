resource "azurerm_subnet" "app" {
  name                 = var.subnet_app.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_app.cidrs

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Storage",
  ]
}

# resource "azurerm_network_security_group" "app" {
#   name                = "nsg-${var.name}-http-redis-001"
#   location            = var.location
#   resource_group_name = var.resource_group_name

#   security_rule {
#     direction                  = "Inbound"
#     priority                   = 100
#     name                       = "AllowRedisBound"
#     destination_port_range     = "6380"
#     protocol                   = "*"
#     source_address_prefixes    = var.app.cidrs
#     source_port_range          = "*"
#     destination_address_prefix = "*"
#     access                     = "Allow"
#   }

#   security_rule {
#     direction                  = "Inbound"
#     priority                   = 110
#     name                       = "DenyRedisInbound"
#     destination_port_range     = "6380"
#     protocol                   = "*"
#     source_address_prefix      = "*"
#     source_port_range          = "*"
#     destination_address_prefix = "*"
#     access                     = "Deny"
#   }

#   # security_rule {
#   #   name                       = "AllowBastionVnetInBound"
#   #   priority                   = 1000
#   #   direction                  = "Inbound"
#   #   access                     = "Allow"
#   #   protocol                   = "*"
#   #   source_port_range          = "*"
#   #   destination_port_ranges     = ["3389","22"]
#   #   source_address_prefix      = "VirtualNetwork"
#   #   destination_address_prefix = "*"
#   # }

#   # security_rule {
#   #   name                       = "AllowBastionVnetOutBound"
#   #   priority                   = 1000
#   #   direction                  = "Outbound"
#   #   access                     = "Allow"
#   #   protocol                   = "*"
#   #   source_port_range          = "*"
#   #   destination_port_ranges     = ["3389","22"]
#   #   source_address_prefix      = "VirtualNetwork"
#   #   destination_address_prefix = "*"
#   # }

#   tags = var.tags
# }

# resource "azurerm_subnet_network_security_group_association" "app" {
#   subnet_id                 = azurerm_subnet.app.id
#   network_security_group_id = azurerm_network_security_group.app.id
# }
