output "main" {
  value = {
    id   = azurerm_redis_cache.main.id
    name = azurerm_redis_cache.main.name
  }
}
