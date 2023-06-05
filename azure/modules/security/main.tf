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

resource "azurerm_monitor_diagnostic_setting" "main" {
  name               = "kv-${var.name}-logs-001"
  target_resource_id = azurerm_key_vault.main.id

  storage_account_id         = var.diagnostics.storage_account_id
  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_log {
    category_group = "audit"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }

  # HACK
  lifecycle {
    ignore_changes = [
      storage_account_id,
      log_analytics_workspace_id,
    ]
  }
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
