variable "name" {
  type = string
}

variable "alias_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kv_allow_ips" {
  type    = list(string)
  default = []
}

variable "id_principal_id" {
  type = string
}

variable "kv_users" {
  type    = map(string)
  default = {}
}

variable "kv_subnets" {
  type    = list(string)
  default = []
}

variable "mysql_key_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

data "azurerm_client_config" "self" {}

resource "azurerm_user_assigned_identity" "main" {
  name                = "id-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
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
  object_id    = var.id_principal_id

  key_permissions = [
    "Get", "List", "WrapKey", "UnwrapKey", "Decrypt"
  ]
}

resource "azurerm_key_vault_access_policy" "users" {
  for_each     = var.kv_users
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.self.tenant_id
  object_id    = each.key

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "GetRotationPolicy", "SetRotationPolicy", "Rotate",
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore",
  ]

  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers",
  ]
}

# ファイアウォールによるアクセス制限により、VPN接続が必要なので管理対象外にする
# resource "azurerm_key_vault_key" "mysql" {
#   count        = var.mysql_key_enabled ? 1 : 0
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

output "user_assigned_identity" {
  value = azurerm_user_assigned_identity.main
}

output "key_vault" {
  value = azurerm_key_vault.main
}
