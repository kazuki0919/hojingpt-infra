# resource "azurerm_cognitive_account" "openai_private" {
#   name                               = "oai-${var.name}-private-${var.location}"
#   custom_subdomain_name              = "oai-${var.name}-private-${var.location}"
#   resource_group_name                = var.resource_group_name
#   location                           = var.location
#   kind                               = "OpenAI"
#   sku_name                           = "S0"

#   dynamic_throttling_enabled         = var.dynamic_throttling_enabled
#   # fqdns                              = var.fqdns
#   local_auth_enabled                 = true
#   outbound_network_access_restricted = false
#   public_network_access_enabled      = false
#   tags                               = var.tags

#   # dynamic "customer_managed_key" {
#   #   for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
#   #   content {
#   #     key_vault_key_id   = customer_managed_key.value.key_vault_key_id
#   #     identity_client_id = customer_managed_key.value.identity_client_id
#   #   }
#   # }

#   # dynamic "identity" {
#   #   for_each = var.identity != null ? [var.identity] : []
#   #   content {
#   #     type         = identity.value.type
#   #     identity_ids = identity.value.identity_ids
#   #   }
#   # }

#   # dynamic "network_acls" {
#   #   for_each = var.network_acls != null ? [var.network_acls] : []
#   #   content {
#   #     default_action = network_acls.value.default_action
#   #     ip_rules       = network_acls.value.ip_rules

#   #     dynamic "virtual_network_rules" {
#   #       for_each = network_acls.value.virtual_network_rules != null ? network_acls.value.virtual_network_rules : []
#   #       content {
#   #         subnet_id                            = virtual_network_rules.value.subnet_id
#   #         ignore_missing_vnet_service_endpoint = virtual_network_rules.value.ignore_missing_vnet_service_endpoint
#   #       }
#   #     }
#   #   }
#   # }

#   # dynamic "storage" {
#   #   for_each = var.storage
#   #   content {
#   #     storage_account_id = storage.value.storage_account_id
#   #     identity_client_id = storage.value.identity_client_id
#   #   }
#   # }
# }

# # resource "azurerm_cognitive_deployment" "openai_private" {
# #   for_each             = var.deployment
# #   cognitive_account_id = azurerm_cognitive_account.openai_private.id
# #   name                 = each.value.name
# #   rai_policy_name      = each.value.rai_policy_name

# #   model {
# #     format  = each.value.model_format
# #     name    = each.value.model_name
# #     version = each.value.model_version
# #   }

# #   scale {
# #     type = each.value.scale_type
# #   }
# # }
