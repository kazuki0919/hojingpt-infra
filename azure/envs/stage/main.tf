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
  env         = "stage"
  tags        = {}
  domain_name = "staging-hojingpt-com"
  host_name   = "staging.hojingpt.com"
}

data "azurerm_resource_group" "main" {
  name = "rg-hojingpt-${local.env}"
}

data "azurerm_dns_zone" "main" {
  name                = local.host_name
  resource_group_name = data.azurerm_resource_group.main.name
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "vnet-hojingpt-${local.env}-001"
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

module "security" {
  source              = "../../modules/security"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
}

module "app" {
  source              = "../../modules/app"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  registory_name      = "crhojingpt${local.env}"
  app_name            = "hojingpt-${local.env}-001"
  user_assigned_ids   = [module.security.user_assigned_identity.id]

  network = {
    name  = module.network.vnet.name
    cidrs = ["10.0.0.0/23"]
  }

  tags = {
    owner   = "yusuke.yoda"
    created = "2023.05.10"
  }
}

module "frontdoor" {
  source              = "../../modules/frontdoor"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "houjingpt-${local.env}-jpeast"

  app = {
    host                   = "ca-hojingpt-stage-001.purplewater-a7ff9cea.japaneast.azurecontainerapps.io"
    private_link_target_id = "/subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-stage/providers/Microsoft.Network/privateLinkServices/pl-hojingpt-stage-001"
  }

  domain = {
    name        = local.domain_name
    host_name   = local.host_name
    dns_zone_id = data.azurerm_dns_zone.main.id
  }

  waf_policy_name = "wafrgHoujingptStage"

  tags = {
    owner   = "yusuke.yoda"
    created = "2023.05.10"
  }
}

module "mysql" {
  source              = "../../modules/database/mysql"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  alias_name          = "houjingpt-${local.env}"
  sku_name            = "B_Standard_B1s"
  dns_vnet_link_name  = "mkctbf32nyz7e" #TODO: random
  db_version          = "8.0.21"
  db_name             = "hojingpt"

  network = {
    name  = module.network.vnet.name
    id    = module.network.vnet.id
    cidrs = ["10.0.2.0/24"]
  }

  storage = {
    iops    = 360
    size_gb = 20
  }
}

module "redis" {
  source               = "../../modules/cache/redis"
  resource_group_name  = data.azurerm_resource_group.main.name
  location             = data.azurerm_resource_group.main.location
  name                 = "houjingpt-${local.env}"
  storage_account_name = "sthojingptredis${local.env}"
}
