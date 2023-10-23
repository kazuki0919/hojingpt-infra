output "user_assigned_identity" {
  value = azurerm_user_assigned_identity.main
}

output "key_vault" {
  value = azurerm_key_vault.main
}

output "key_vault_access_policy" {
  value = azurerm_key_vault_access_policy.main
}
