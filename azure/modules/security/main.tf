data "azurerm_client_config" "self" {}

resource "azurerm_user_assigned_identity" "main" {
  name                = "id-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.name}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.self.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  sku_name                    = "standard"

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = var.kv_allow_ips
    virtual_network_subnet_ids = var.kv_subnets
  }

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "main" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.self.tenant_id
  object_id    = azurerm_user_assigned_identity.main.principal_id

  key_permissions = [
    "Get",
    "List",
    "WrapKey",
    "UnwrapKey",
    "Decrypt",
  ]
}

resource "azurerm_key_vault_access_policy" "users" {
  for_each     = var.kv_users
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.self.tenant_id
  object_id    = each.key

  key_permissions = [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "GetRotationPolicy",
    "SetRotationPolicy",
    "Rotate",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "ManageContacts",
    "ManageIssuers",
    "GetIssuers",
    "ListIssuers",
    "SetIssuers",
    "DeleteIssuers",
  ]
}

# TODO: これ本当に必要？
# resource "azurerm_key_vault_key" "mysql" {
#   name         = "key-mysql-${var.alias_name}"
#   key_vault_id = azurerm_key_vault.main.id
#   key_type     = "RSA"
#   key_size     = 2048

#   key_opts = [
#     "sign", "verify", "wrapKey", "unwrapKey", "encrypt", "decrypt",
#   ]

#   lifecycle {
#     ignore_changes = [not_before_date]
#   }
# }
