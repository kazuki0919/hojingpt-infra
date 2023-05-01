terraform {
  backend "azurerm" {
    resource_group_name  = "rg-hojingpt-prod"
    storage_account_name = "sthojingptterraformprod"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  name     = "hojingpt"
  env      = "prod"
  location = "japaneast"
  rgname   = "rg-${local.name}-${local.env}"
}

# resource "azurerm_virtual_network" "public" {
#   name                = "vnet-${local.name}-${local.location}-${local.env}"
#   address_space       = ["10.100.0.0/16"]
#   location            = local.location
#   resource_group_name = local.rgname
# }
