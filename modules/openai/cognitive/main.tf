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

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scale.0.capacity]
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
    private_dns_zone_ids = [var.private_endpoint.dns_zone_id]
  }
}

#########################################################################
# Diasnostic Setting
#########################################################################
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                          = var.diagnostics == null ? 0 : 1
  name                           = "cog-${var.name}-private-logs-${var.name_suffix}"
  target_resource_id             = azurerm_cognitive_account.openai_private.id
  log_analytics_workspace_id     = var.diagnostics.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"
  storage_account_id             = var.diagnostics.storage_account_id

  enabled_log {
    category = "Audit"

    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "RequestResponse"

    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "Trace"

    retention_policy {
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  lifecycle {
    # HACK: Suppresses diff generated by plan
    ignore_changes = [log_analytics_destination_type]
  }
}
