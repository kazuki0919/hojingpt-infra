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
  name = "hojingpt"
  env  = "stage"
  tags = {}

  subnet_app     = "snet-${local.name}-${local.env}-001"
  subnet_bastion = "snet-${local.name}-${local.env}-002"
}

data "azurerm_resource_group" "main" {
  name = "rg-${local.name}-${local.env}"
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "vnet-${local.name}-stage-001"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "${local.subnet_app}" = {
      address_prefix    = ["10.0.0.0/23"]
      service_endpoints = ["Microsoft.KeyVault"]
    }
    "${local.subnet_bastion}" = {
      address_prefix    = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.KeyVault"]
    }
  }

  tags = local.tags
}

module "app" {
  source                     = "../../modules/app"
  resource_group_name        = data.azurerm_resource_group.main.name
  location                   = data.azurerm_resource_group.main.location
  registory_name             = "cr${local.name}${local.env}"
  app_name                   = "${local.name}-${local.env}-001"

  tags = {
    owner   = "yusuke.yoda"
    created = "2023.05.10"
  }
}
