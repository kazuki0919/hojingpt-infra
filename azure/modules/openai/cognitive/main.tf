#########################################################################
# Cognitive Service
#########################################################################
resource "azurerm_cognitive_account" "openai_private" {
  name                               = "cog-${var.name}-private-${var.name_suffix}"
  custom_subdomain_name              = "cog-${var.name}-private-${var.name_suffix}"
  resource_group_name                = var.resource_group_name
  location                           = var.location
  kind                               = "OpenAI"
  sku_name                           = "S0"
  dynamic_throttling_enabled         = false
  fqdns                              = []
  local_auth_enabled                 = true
  outbound_network_access_restricted = false
  public_network_access_enabled      = true
  tags                               = var.tags

  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : [true]
    content {
      default_action = var.network_acls.default_action
      ip_rules       = var.network_acls.ip_rules

      dynamic "virtual_network_rules" {
        for_each = var.network_acls.virtual_network_rules
        content {
          subnet_id                            = virtual_network_rules.value.subnet_id
          ignore_missing_vnet_service_endpoint = virtual_network_rules.value.ignore_missing_vnet_service_endpoint
        }
      }
    }
  }
}

resource "azurerm_cognitive_deployment" "openai_private" {
  for_each             = var.deployments
  cognitive_account_id = azurerm_cognitive_account.openai_private.id
  name                 = each.key
  rai_policy_name      = each.value.rai_policy_name

  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }

  scale {
    type     = each.value.scale_type
    capacity = each.value.scale_capacity
  }
}

#########################################################################
# Private Endpoint
#########################################################################
resource "azurerm_private_endpoint" "main" {
  count               = var.private_endpoint == null ? 0 : 1
  name                = "pep-${var.name}-cog-${var.name_suffix}"
  location            = var.private_endpoint.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "private-openai-connection"
    private_connection_resource_id = azurerm_cognitive_account.openai_private.id
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_endpoint.dns_zone.id]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  count                 = var.private_endpoint == null ? 0 : 1
  name                  = "link-${var.name}-cog-${var.name_suffix}"
  private_dns_zone_name = var.private_endpoint.dns_zone.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.private_endpoint.id
  registration_enabled  = false
  tags                  = var.tags
}

#########################################################################
# Diasnostic Setting
#########################################################################
# resource "azurerm_monitor_diagnostic_setting" "setting" {
#   for_each                       = var.diagnostic_setting
#   name                           = each.value.name
#   target_resource_id             = azurerm_cognitive_account.openai_private.id
#   log_analytics_workspace_id     = each.value.log_analytics_workspace_id
#   log_analytics_destination_type = each.value.log_analytics_destination_type
#   eventhub_name                  = each.value.eventhub_name
#   eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id
#   storage_account_id             = each.value.storage_account_id
#   partner_solution_id            = each.value.partner_solution_id

#   dynamic "enabled_log" {
#     for_each = try(each.value.audit_log_retention_policy.enabled, null) == null ? [] : [1]

#     content {
#       category = "Audit"

#       retention_policy {
#         enabled = each.value.audit_log_retention_policy.enabled
#         days    = each.value.audit_log_retention_policy.days
#       }
#     }
#   }

#   dynamic "enabled_log" {
#     for_each = try(each.value.request_response_log_retention_policy.enabled, null) == null ? [] : [1]

#     content {
#       category = "RequestResponse"

#       retention_policy {
#         enabled = each.value.request_response_log_retention_policy.enabled
#         days    = each.value.request_response_log_retention_policy.days
#       }
#     }
#   }

#   dynamic "enabled_log" {
#     for_each = try(each.value.trace_log_retention_policy.enabled, null) == null ? [] : [1]

#     content {
#       category = "Trace"

#       retention_policy {
#         enabled = each.value.trace_log_retention_policy.enabled
#         days    = each.value.trace_log_retention_policy.days
#       }
#     }
#   }

#   dynamic "metric" {
#     for_each = try(each.value.metric_retention_policy.enabled, null) == null ? [] : [1]

#     content {
#       category = "AllMetrics"

#       retention_policy {
#         enabled = each.value.metric_retention_policy.enabled
#         days    = each.value.metric_retention_policy.days
#       }
#     }
#   }
# }
