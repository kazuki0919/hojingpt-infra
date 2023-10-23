output "vnet" {
  value = azurerm_virtual_network.main
}

output "subnet_app" {
  value = azurerm_subnet.app
}

output "subnet_mysql" {
  value = azurerm_subnet.mysql
}

output "subnet_bastion" {
  value = azurerm_subnet.bastion
}
