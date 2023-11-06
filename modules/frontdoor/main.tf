data "azurerm_container_app" "app" {
  count               = var.container.app_name == null ? 0 : 1
  name                = "ca-${var.container.app_name}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_link_service" "app" {
  count                                       = var.container.app_name == null ? 0 : 1
  name                                        = "pl-${var.container.app_name}"
  location                                    = var.location
  resource_group_name                         = var.resource_group_name
  load_balancer_frontend_ip_configuration_ids = var.container.lb_frontend_ids

  nat_ip_configuration {
    name      = "snet-${var.container.app_name}-1"
    primary   = true
    subnet_id = var.container.subnet_id
  }

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_profile" "main" {
  count                    = var.profile_id == null ? 1 : 0
  name                     = "afd-${var.name}"
  resource_group_name      = var.resource_group_name
  sku_name                 = var.sku_name
  response_timeout_seconds = var.response_timeout_seconds
  tags                     = var.tags
}

locals {
  profile_id = var.profile_id == null ? azurerm_cdn_frontdoor_profile.main.0.id : var.profile_id
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "fde-${var.name}"
  cdn_frontdoor_profile_id = local.profile_id
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "fes-${var.name}-001"
  cdn_frontdoor_profile_id = local.profile_id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 0

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 1000
  }
}

resource "azurerm_cdn_frontdoor_origin" "app" {
  count                         = var.container.app_name == null ? 0 : 1
  name                          = "fdo-${var.name}-001"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id

  enabled                        = true
  host_name                      = data.azurerm_container_app.app.0.ingress.0.fqdn
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = data.azurerm_container_app.app.0.ingress.0.fqdn
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    location               = var.location
    private_link_target_id = azurerm_private_link_service.app.0.id
    request_message        = "frontdoor"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "main" {
  for_each                 = var.custom_domains
  name                     = each.key
  cdn_frontdoor_profile_id = local.profile_id
  dns_zone_id              = each.value.dns_zone_id
  host_name                = each.value.host_name

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }

  lifecycle {
    ignore_changes = [dns_zone_id]
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "main" {
  name                     = var.default_rule_set_name
  cdn_frontdoor_profile_id = local.profile_id
}

resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "fdr-${var.name}-001"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id

  cdn_frontdoor_origin_ids = [
  ]

  cdn_frontdoor_custom_domain_ids = [
    for domain in azurerm_cdn_frontdoor_custom_domain.main : domain.id
  ]

  cdn_frontdoor_rule_set_ids = [
    azurerm_cdn_frontdoor_rule_set.main.id,
  ]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "MatchRequest"
  link_to_default_domain = true
  https_redirect_enabled = true

  depends_on = [azurerm_cdn_frontdoor_origin_group.main]
}

resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  count               = var.waf_enabled ? 1 : 0
  name                = "waffd${replace(var.name, "-", "")}"
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  enabled             = true
  mode                = var.waf_mode

  custom_block_response_body        = "QmxvY2tlZCBieSBXQUY=" # "Blocked by WAF"
  custom_block_response_status_code = 403

  # IP white list
  dynamic "custom_rule" {
    for_each = length(var.waf_allow_cidrs) > 0 ? [true] : []
    content {
      action                         = "Block"
      enabled                        = true
      name                           = "IPWhiteList"
      priority                       = 100
      rate_limit_duration_in_minutes = 1
      rate_limit_threshold           = 100
      type                           = "MatchRule"

      match_condition {
        match_values       = var.waf_allow_cidrs
        match_variable     = "SocketAddr"
        negation_condition = true
        operator           = "IPMatch"
        transforms         = []
      }
    }
  }

  managed_rule {
    action  = "Log"
    type    = "Microsoft_DefaultRuleSet"
    version = "2.0"
  }

  managed_rule {
    action  = "Log"
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "main" {
  count                    = var.waf_enabled ? 1 : 0
  name                     = "waf-${var.name}-001"
  cdn_frontdoor_profile_id = local.profile_id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.0.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }

        dynamic "domain" {
          for_each = var.custom_domains
          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.main[domain.key].id
          }
        }

        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  count              = var.diagnostics == null ? 0 : 1
  name               = "afd-${var.name}-logs-001"
  target_resource_id = local.profile_id

  storage_account_id         = var.diagnostics.storage_account_id
  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id

  enabled_log {
    category = "FrontDoorAccessLog"
  }

  enabled_log {
    category = "FrontDoorHealthProbeLog"
  }

  enabled_log {
    category = "FrontDoorWebApplicationFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }
}
