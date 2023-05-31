resource "azurerm_container_registry" "main" {
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

resource "azurerm_container_app_environment" "main" {
  name                           = "cae-${var.name}-001"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.subnet_id
  internal_load_balancer_enabled = true
  tags                           = var.tags

  # HACK: Once created, it cannot be changed by terraform... see: https://stackoverflow.com/questions/73811960/how-can-i-modify-container-app-environment-customerid
  lifecycle {
    ignore_changes = [log_analytics_workspace_id]
  }
}

# resource "azurerm_private_link_service" "main" {
#   count               = length(var.load_balancer_frontend_ip_configuration_ids) > 0 ? 1 : 0
#   name                = "pl-${var.name}"
#   location            = var.location
#   resource_group_name = var.resource_group_name

#   load_balancer_frontend_ip_configuration_ids = var.load_balancer_frontend_ip_configuration_ids

#   nat_ip_configuration {
#     name      = "snet-${var.name}-1"
#     primary   = true
#     subnet_id = var.subnet_id
#   }

#   tags = var.tags
# }
