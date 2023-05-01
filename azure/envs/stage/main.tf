terraform {
  backend "azurerm" {
    resource_group_name  = "rg-hojingpt-stage"
    storage_account_name = "sthojingptterraformstage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  name     = "hojingpt"
  env      = "stage"
  location = "japaneast"
  rgname   = "rg-${local.name}-${local.env}"
}

# resource "azurerm_virtual_network" "public" {
#   name                = "vnet-${local.name}-${local.location}-stage"
#   address_space       = ["10.100.0.0/16"]
#   location            = local.location
#   resource_group_name = local.rgname
# }
