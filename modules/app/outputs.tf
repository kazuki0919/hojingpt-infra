output "registry" {
  value = azurerm_container_registry.main
}

output "env" {
  value = azurerm_container_app_environment.main
}

# output "private_link_service" {
#   value = one(azurerm_private_link_service.main)
# }
