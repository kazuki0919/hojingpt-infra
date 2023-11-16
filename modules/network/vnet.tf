resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.name}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}
