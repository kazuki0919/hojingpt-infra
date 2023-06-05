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
  name                          = "st${replace(var.name, "-", "")}logs"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  public_network_access_enabled = false
  account_tier                  = "Standard"
  account_kind                  = "StorageV2"
  account_replication_type      = "GRS"
}

output "storage_account" {
  value = azurerm_storage_account.main
}

output "log_analytics_workspace" {
  value = azurerm_log_analytics_workspace.main
}
