data "azurerm_container_app" "app" {
  name                = "ca-${var.container_app.name}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_link_service" "app" {
  name                                        = "pl-${var.container_app.name}"
  location                                    = var.location
  resource_group_name                         = var.resource_group_name
  load_balancer_frontend_ip_configuration_ids = var.container_app.lb_frontend_ids

  nat_ip_configuration {
    name      = "snet-${var.container_app.name}-1"
    primary   = true
    subnet_id = var.container_app.subnet_id
  }

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                     = "afd-${var.name}"
  resource_group_name      = var.resource_group_name
  sku_name                 = var.sku_name
  response_timeout_seconds = 60
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "fde-${var.name}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "fes-${var.name}-001"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  #TODO: Shoud change value to 10
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 0

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  #TODO
  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Http"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "app" {
  name                          = "fdo-${var.name}-001"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id

  enabled                        = true
  host_name                      = data.azurerm_container_app.app.ingress.0.fqdn
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = data.azurerm_container_app.app.ingress.0.fqdn
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    location               = var.location
    private_link_target_id = azurerm_private_link_service.app.id
    request_message        = "frontdoor"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "main" {
  name                     = var.domain.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  dns_zone_id              = var.domain.dns_zone_id
  host_name                = var.domain.host_name

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "fdr-${var.name}-001"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id

  cdn_frontdoor_origin_ids = [
  ]

  cdn_frontdoor_custom_domain_ids = [
    azurerm_cdn_frontdoor_custom_domain.main.id,
  ]

  supported_protocols = ["Http", "Https"]
  patterns_to_match   = ["/*"]
  # forwarding_protocol    = "HttpsOnly"
  forwarding_protocol    = "MatchRequest"
  link_to_default_domain = true
  https_redirect_enabled = true
}

resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                = var.waf_policy_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  enabled             = true
  mode                = "Detection"

  managed_rule {
    action  = "Allow" #HACK unneeded...
    type    = "Microsoft_DefaultRuleSet"
    version = "2.0"
  }

  managed_rule {
    action  = "Allow" #HACK unneeded...
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
  }

  lifecycle {
    ignore_changes = [
      #HACK unneeded...
      managed_rule.0.action,
      managed_rule.1.action,
    ]
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "main" {
  name                     = "waf-${var.name}-001"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }

        domain {
          cdn_frontdoor_domain_id = replace(azurerm_cdn_frontdoor_custom_domain.main.id, "customDomains", "customdomains") #HACK
        }

        patterns_to_match = ["/*"]
      }
    }
  }
}
