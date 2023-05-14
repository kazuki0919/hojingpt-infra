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

variable "user_assigned_ids" {
  type = list(string)
}

variable "network" {
  type = object({
    name  = string
    cidrs = list(string)
  })
}

resource "azurerm_container_registry" "app" {
  name                = var.registory_name
  resource_group_name = var.resource_group_name
  location            = var.location

  admin_enabled                 = true
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false
  export_policy_enabled         = true
  network_rule_bypass_option    = "AzureServices"
  public_network_access_enabled = true
  quarantine_policy_enabled     = false
  zone_redundancy_enabled       = false
  sku                           = "Basic"

  identity {
    identity_ids = var.user_assigned_ids
    type         = "UserAssigned"
  }

  retention_policy {
    days    = 7
    enabled = false
  }

  trust_policy {
    enabled = false
  }

  tags = var.tags
}

resource "azurerm_subnet" "app" {
  name                 = "snet-${var.app_name}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.network.name
  address_prefixes     = var.network.cidrs
  service_endpoints    = ["Microsoft.KeyVault"]
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
