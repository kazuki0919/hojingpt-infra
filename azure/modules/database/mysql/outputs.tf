output "main" {
  value     = {
    id   = azurerm_mysql_flexible_server.main.id
    name = azurerm_mysql_flexible_server.main.name
  }
}
