output "main" {
  value = {
    id   = azurerm_cdn_frontdoor_profile.main.id
    name = azurerm_cdn_frontdoor_profile.main.name
  }
}
