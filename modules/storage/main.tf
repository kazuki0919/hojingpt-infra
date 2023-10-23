variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "network" {
  type = object({
    subnet_id               = string
    allow_ips               = optional(list(string), [])
    private_link_access_ids = optional(list(string), [])
  })
  default = null
}

variable "diagnostics" {
  type = object({
    log_analytics_workspace_id = string
    storage_account_id         = string
  })
}

variable "backup_enabled" {
  type    = bool
  default = true
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

data "azurerm_client_config" "self" {}

########################################################
# Blob Storage
########################################################
resource "azurerm_storage_account" "docs" {
  name                            = "st${replace(var.name, "-", "")}docs"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = "ZRS"

  blob_properties {
    versioning_enabled            = true
    change_feed_enabled           = var.backup_enabled
    change_feed_retention_in_days = var.backup_enabled ? var.backup_retention_days + 1 : null

    dynamic "delete_retention_policy" {
      for_each = var.backup_enabled ? [true] : []
      content {
        days = var.backup_retention_days + 1
      }
    }

    dynamic "restore_policy" {
      for_each = var.backup_enabled ? [true] : []
      content {
        days = var.backup_retention_days
      }
    }
  }

  dynamic "network_rules" {
    for_each = var.network == null ? [] : [true]
    content {
      default_action             = "Deny"
      ip_rules                   = var.network.allow_ips
      virtual_network_subnet_ids = [var.network.subnet_id]

      dynamic "private_link_access" {
        for_each = var.network.private_link_access_ids
        content {
          endpoint_resource_id = private_link_access.value
          endpoint_tenant_id   = data.azurerm_client_config.self.tenant_id
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore private_link_access as storageDataScanner is automatically assigned by Defender for Cloud.
      network_rules.0.private_link_access,
    ]
  }

  tags = var.tags
}

resource "azurerm_storage_management_policy" "docs" {
  storage_account_id = azurerm_storage_account.docs.id

  rule {
    name    = "DeletePreviousVersions"
    enabled = true
    filters {
      blob_types = ["blockBlob", "appendBlob"]
    }
    actions {
      version {
        delete_after_days_since_creation = var.backup_enabled ? var.backup_retention_days + 1 : 7
      }
    }
  }
}

resource "azurerm_storage_container" "docs_contents" {
  name                  = "contents"
  storage_account_name  = azurerm_storage_account.docs.name
  container_access_type = "private"
}

########################################################
# Logging
########################################################
resource "azurerm_monitor_diagnostic_setting" "docs" {
  name               = "st-${var.name}-docs-001"
  target_resource_id = "/subscriptions/${data.azurerm_client_config.self.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${azurerm_storage_account.docs.name}/blobServices/default"

  storage_account_id         = var.diagnostics.storage_account_id
  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Capacity"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "Transaction"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}

########################################################
# Backup
########################################################
resource "azurerm_data_protection_backup_vault" "docs" {
  count               = var.backup_enabled ? 1 : 0
  name                = "bk-${var.name}-docs-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  datastore_type      = "VaultStore"

  # TODO: Change to "ZoneRedundant" later.
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/21300
  redundancy = "LocallyRedundant"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "docs" {
  count                = var.backup_enabled ? 1 : 0
  scope                = azurerm_storage_account.docs.id
  role_definition_name = "Storage Account Backup Contributor"
  principal_id         = one(azurerm_data_protection_backup_vault.docs).identity[0].principal_id
}

resource "azurerm_data_protection_backup_policy_blob_storage" "docs" {
  count              = var.backup_enabled ? 1 : 0
  name               = "bkp-${var.name}-docs-001"
  vault_id           = one(azurerm_data_protection_backup_vault.docs).id
  retention_duration = "P${var.backup_retention_days}D"
}

resource "azurerm_data_protection_backup_instance_blob_storage" "docs" {
  count              = var.backup_enabled ? 1 : 0
  name               = "bki-${var.name}-docs-001"
  vault_id           = one(azurerm_data_protection_backup_vault.docs).id
  location           = var.location
  storage_account_id = azurerm_storage_account.docs.id
  backup_policy_id   = one(azurerm_data_protection_backup_policy_blob_storage.docs).id
  depends_on         = [azurerm_role_assignment.docs]
}
