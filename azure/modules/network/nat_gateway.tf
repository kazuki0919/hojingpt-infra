# ################################################################################
# # NAT Gateway (primary)
# ################################################################################
# resource "azurerm_public_ip" "nat_gateway_001" {
#   name                = "pip-${var.name}-ng-001"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   zones               = ["1"]
# }

# resource "azurerm_public_ip_prefix" "nat_gateway_001" {
#   name                = "pip-${var.name}-ng-001"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   prefix_length       = 28
#   zones               = ["1"]
# }

# resource "azurerm_nat_gateway" "nat_gateway_001" {
#   name                    = "ng-${var.name}-001"
#   location                = var.location
#   resource_group_name     = var.resource_group_name
#   public_ip_address_ids   = [azurerm_public_ip.nat_gateway_001.id]
#   public_ip_prefix_ids    = [azurerm_public_ip_prefix.nat_gateway_001.id]
#   sku_name                = "Standard"
#   idle_timeout_in_minutes = 10
#   zones                   = ["1"]
# }

# ################################################################################
# # NAT Gateway (secondary)
# ################################################################################
# resource "azurerm_public_ip" "nat_gateway_002" {
#   name                = "pip-${var.name}-ng-002"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   zones               = ["2"]
# }

# resource "azurerm_public_ip_prefix" "nat_gateway_002" {
#   name                = "pip-${var.name}-ng-002"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   prefix_length       = 28
#   zones               = ["2"]
# }

# resource "azurerm_nat_gateway" "nat_gateway_002" {
#   name                    = "ng-${var.name}-002"
#   location                = var.location
#   resource_group_name     = var.resource_group_name
#   public_ip_address_ids   = [azurerm_public_ip.nat_gateway_002.id]
#   public_ip_prefix_ids    = [azurerm_public_ip_prefix.nat_gateway_002.id]
#   sku_name                = "Standard"
#   idle_timeout_in_minutes = 10
#   zones                   = ["2"]
# }
