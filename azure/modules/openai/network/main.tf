variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "subnets" {
  type = map(object({
    cidrs = list(string)
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_virtual_network" "main" {
  count               = var.vnet_name == null ? 1 : 0
  name                = "vnet-${var.name}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "main" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name == null ? one(azurerm_virtual_network.main).name : var.vnet_name
  address_prefixes     = each.value.cidrs

  service_endpoints = [
    "Microsoft.CognitiveServices",
  ]

  private_link_service_network_policies_enabled = false
  private_endpoint_network_policies_enabled     = false
}

output "vnet_name" {
  value = var.vnet_name == null ? one(azurerm_virtual_network.main).name : var.vnet_name
}

output "subnets" {
  value = azurerm_subnet.main
}
