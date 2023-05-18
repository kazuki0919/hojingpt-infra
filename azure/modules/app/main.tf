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

variable "load_balancer_frontend_ip_configuration_ids" {
  type = list(string)
}

variable "subnet_id" {
  type = string
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

data "azurerm_container_app_environment" "app" {
  name                = "cae-${var.app_name}"
  resource_group_name = var.resource_group_name
}

data "azurerm_container_app" "app" {
  name                = "ca-${var.app_name}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_link_service" "main" {
  count               = length(var.load_balancer_frontend_ip_configuration_ids) > 0 ? 1 : 0
  name                = "pl-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  load_balancer_frontend_ip_configuration_ids = var.load_balancer_frontend_ip_configuration_ids

  nat_ip_configuration {
    name      = "snet-${var.app_name}-1"
    primary   = true
    subnet_id = var.subnet_id
  }

  tags = var.tags
}

output "registry" {
  value = azurerm_container_registry.app
}

output "env" {
  value = data.azurerm_container_app_environment.app
}

output "container" {
  value = data.azurerm_container_app.app
}

output "private_link_service" {
  value = one(azurerm_private_link_service.main)
}
