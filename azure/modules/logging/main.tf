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
  type = number
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
}

output "log_analytics_workspace" {
  value = azurerm_log_analytics_workspace.main
}
