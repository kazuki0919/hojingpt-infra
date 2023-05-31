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
