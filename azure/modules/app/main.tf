variable "app_name" {
  type = string
}

variable "registory_name" {
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

resource "azurerm_container_registry" "app" {
  name                = var.registory_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  tags                = var.tags
}

data "azurerm_container_app_environment" "app" {
  name                = "cae-${var.app_name}"
  resource_group_name = var.resource_group_name
}

data "azurerm_container_app" "app" {
  name                = "ca-${var.app_name}"
  resource_group_name = var.resource_group_name
}

output "registory" {
  value = azurerm_container_registry.app
}

output "env" {
  value = data.azurerm_container_app_environment.app
}

output "app" {
  value = data.azurerm_container_app.app
}
