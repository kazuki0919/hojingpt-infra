data "azurerm_container_app" "aoai" {
  count               = var.container.aoai_name == null ? 0 : 1
  name                = "ca-${var.container.aoai_name}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_cdn_frontdoor_origin_group" "aoai" {
  count                    = var.container.aoai_name == null ? 0 : 1
  name                     = "fes-${var.name}-002"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 0

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 1000
  }
}

resource "azurerm_cdn_frontdoor_origin" "aoai" {
  count                         = var.container.aoai_name == null ? 0 : 1
  name                          = "fdo-${var.name}-002"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aoai.0.id

  enabled                        = true
  host_name                      = data.azurerm_container_app.aoai.0.ingress.0.fqdn
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = data.azurerm_container_app.aoai.0.ingress.0.fqdn
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    location               = var.location
    private_link_target_id = azurerm_private_link_service.app.id
    request_message        = "frontdoor"
  }
}

resource "azurerm_cdn_frontdoor_rule" "aoai" {
  count                     = var.container.aoai_name == null ? 0 : 1
  name                      = "AOAIRoutingRule"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.main.id
  order                     = 1
  behavior_on_match         = "Continue"

  conditions {
    query_string_condition {
      operator     = "Contains"
      match_values = ["aoai=1"]
      transforms   = ["Lowercase"]
    }
  }

  actions {
    route_configuration_override_action {
      cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aoai.0.id
      forwarding_protocol           = "MatchRequest"
      cache_behavior                = "Disabled"
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.aoai,
    azurerm_cdn_frontdoor_origin_group.aoai,
  ]
}
