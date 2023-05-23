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
  domain_name = "staging-hojingpt-com"
  host_name   = "staging.hojingpt.com"

  allow_ips = [
    "126.208.101.129/32", # takahito.yamatoya's home IP. To be removed at a later.
    "222.230.117.190/32", # yusuke.yoda's home IP. To be removed at a later.
    "150.249.202.236/32", # givery's office 8F
    "150.249.192.10/32",  # givery's office 7F
  ]

  users = {
    "ad94dd20-bb7f-46e6-a326-73925eef35ab" = "yusuke.yoda@givery.onmicrosoft.com"
    "7f9d0fd2-8d30-48d4-86fc-9cb0ddcb5e1f" = "takahito.yamatoya@givery.onmicrosoft.com"
  }

  tags = {
    owner   = "yusuke.yoda"
    created = "2023.05.10"
  }
}

data "azurerm_resource_group" "main" {
  name = "rg-hojingpt-${local.env}"
}

data "azurerm_lb" "kubernetes_internal" {
  name                = "kubernetes-internal"
  resource_group_name = "mc_purplewater-a7ff9cea-rg_purplewater-a7ff9cea_japaneast"
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "vnet-hojingpt-${local.env}-001"
  address_space       = ["10.0.0.0/16"]

  app = {
    name  = "snet-hojingpt-${local.env}-001"
    cidrs = ["10.0.0.0/23"]
  }

  mysql = {
    name  = "snet-hojingpt-${local.env}-002"
    cidrs = ["10.0.2.0/24"]
  }

  vm = {
    name  = "snet-hojingpt-${local.env}-003"
    cidrs = ["10.0.4.0/23"]
  }

  tags = local.tags
}

module "security" {
  source              = "../../modules/security"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  alias_name          = "houjingpt-${local.env}"
  id_principal_id     = module.security.user_assigned_identity.principal_id
  kv_allow_ips        = local.allow_ips
  kv_users            = local.users

  kv_subnets = [
    module.network.subnet_app.id,
    module.network.subnet_mysql.id,
  ]

  tags = local.tags
}

module "logging" {
  source              = "../../modules/logging"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  retention_in_days   = 30
}

module "bastion" {
  source = "../../modules/bastion"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  subnet_id           = module.network.subnet_vm.id
  ssh_key             = "ssh-hojingpt-${local.env}-001"
  allow_ips           = local.allow_ips
}

module "app" {
  source              = "../../modules/app"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  registory_name      = "crhojingpt${local.env}"
  app_name            = "hojingpt-${local.env}-001"
  user_assigned_ids   = [module.security.user_assigned_identity.id]
  subnet_id           = module.network.subnet_app.id
  tags                = local.tags

  load_balancer_frontend_ip_configuration_ids = data.azurerm_lb.kubernetes_internal.frontend_ip_configuration.*.id
  log_analytics_workspace_id                  = module.logging.log_analytics_workspace.id
}

module "frontdoor" {
  source              = "../../modules/frontdoor"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "houjingpt-${local.env}-jpeast"
  waf_policy_name     = "wafrgHoujingptStage"

  app = {
    host                   = module.app.container.ingress.0.fqdn
    private_link_target_id = module.app.private_link_service.id
  }

  domain = {
    name        = local.domain_name
    host_name   = local.host_name
    dns_zone_id = "/subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-stage/providers/Microsoft.Network/dnsZones/staging.hojingpt.com" #TODO
  }

  tags = local.tags
}

module "mysql" {
  source              = "../../modules/database/mysql"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  alias_name          = "houjingpt-${local.env}"
  sku_name            = "B_Standard_B1s"
  dns_vnet_link_name  = "mkctbf32nyz7e" #TODO: random
  key_vault_id        = module.security.key_vault.id
  db_version          = "8.0.21"
  db_name             = "hojingpt"

  network = {
    vnet_id   = module.network.vnet.id
    subnet_id = module.network.subnet_mysql.id
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
  name                 = "hojingpt-${local.env}"
  alias_name           = "houjingpt-${local.env}"
  storage_account_name = "sthojingptredis${local.env}"
  user_assigned_ids    = [module.security.user_assigned_identity.id]
  subnet_id            = module.network.subnet_app.id
  tags                 = local.tags

  private_service_connection_suffix = "130d0c9d-f74f-4f81-b0f6-c76ec0d36016" #TODO: random_uuid
}
