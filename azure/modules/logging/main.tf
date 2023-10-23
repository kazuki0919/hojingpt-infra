variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "retention_in_days" {
  type    = number
  default = 30
}

variable "storage_replication_type" {
  type    = string
  default = "ZRS"
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

resource "azurerm_storage_account" "main" {
  name                            = "st${replace(var.name, "-", "")}logs"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = var.storage_replication_type
}

output "diagnostics" {
  value = {
    storage_account_id         = azurerm_storage_account.main.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }
}
