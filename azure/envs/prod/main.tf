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
  env = "prod"

  domains = [
    "hojingpt.com",
    "hojingai.com",
  ]

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
    service = "hojingpt"
    env     = local.env
  }
}

data "azurerm_resource_group" "main" {
  name = "rg-hojingpt-${local.env}"
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  address_space       = ["10.1.0.0/16"]

  subnet_app = {
    name  = "snet-hojingpt-${local.env}-001"
    cidrs = ["10.1.0.0/20"]
  }

  subnet_mysql = {
    name  = "snet-hojingpt-${local.env}-002"
    cidrs = ["10.1.16.0/24"]
  }

  subnet_bastion = {
    cidrs = ["10.1.17.0/24"]
  }

  tags = local.tags
}

module "logging" {
  source              = "../../modules/logging"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  tags                = local.tags
}

locals {
  diagnostics = {
    storage_account_id         = module.logging.storage_account.id
    log_analytics_workspace_id = module.logging.log_analytics_workspace.id
  }
}

module "security" {
  source              = "../../modules/security"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  kv_allow_ips        = local.allow_ips
  kv_users            = local.users

  kv_subnets = [
    module.network.subnet_app.id,
    module.network.subnet_mysql.id,
  ]

  diagnostics = local.diagnostics
  tags        = local.tags
}

module "monitoring" {
  source              = "../../modules/monitoring"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = "eastasia"
  name                = "hojingpt-${local.env}"
  tags                = local.tags
}

module "bastion" {
  source              = "../../modules/bastion"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  ssh_key             = "ssh-hojingpt-${local.env}-001"
  bastion_subnet_id   = module.network.subnet_bastion.id
  vm_subnet_id        = module.network.subnet_app.id
  diagnostics         = local.diagnostics
  tags                = local.tags
}

module "redis" {
  source              = "../../modules/cache/redis"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  user_assigned_ids   = [module.security.user_assigned_identity.id]

  network = {
    vnet_id   = module.network.vnet.id
    subnet_id = module.network.subnet_app.id
  }

  sku_name                        = "Premium"
  family                          = "P"
  capacity                        = 1
  zones                           = ["1", "2"]
  maxfragmentationmemory_reserved = 642
  maxmemory_delta                 = 642
  maxmemory_reserved              = 642

  rdb = {
    backup_frequency          = 60
    backup_max_snapshot_count = 1
  }

  # Tue 01:00-06:00 JST
  maintenance = {
    day_of_week    = "Monday"
    start_hour_utc = 16
  }

  diagnostics = local.diagnostics
  tags        = local.tags
}

module "mysql" {
  source              = "../../modules/database/mysql"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  key_vault_id        = module.security.key_vault.id
  db_name             = "hojingpt"
  administrator_login = "hojingpt"

  network = {
    vnet_id   = module.network.vnet.id
    subnet_id = module.network.subnet_mysql.id
  }

  sku_name = "MO_Standard_E2ads_v5"

  high_availability = {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "3"
  }

  storage = {
    iops    = 684
    size_gb = 128
  }

  # Tue 03:00-04:00 JST
  maintenance = {
    day_of_week  = 1
    start_hour   = 18
    start_minute = 0
  }

  diagnostics = local.diagnostics
  tags        = local.tags
}

module "app" {
  source              = "../../modules/app"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  registory_name      = "crhojingpt${local.env}"
  user_assigned_ids   = [module.security.user_assigned_identity.id]
  subnet_id           = module.network.subnet_app.id
  key_vault_object_id = module.security.key_vault_access_policy.object_id
  diagnostics         = local.diagnostics
  tags                = local.tags
}

data "azurerm_lb" "kubernetes_internal" {
  name                = "kubernetes-internal"
  resource_group_name = "MC_salmonsmoke-97ec2d6e-rg_salmonsmoke-97ec2d6e_japaneast"
}

module "frontdoor" {
  source              = "../../modules/frontdoor"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}-jpeast"

  container_app = {
    name            = "hojingpt-${local.env}-001"
    subnet_id       = module.network.subnet_app.id
    lb_frontend_ids = data.azurerm_lb.kubernetes_internal.frontend_ip_configuration.*.id
  }

  # TODO
  # custom_domains = {
  #   for domain in local.domains : "${replace(domain, ".", "-")}" => {
  #     host_name = domain
  #   }
  # }

  origin_host_header = "ca-hojingpt-prod-001.salmonsmoke-97ec2d6e.japaneast.azurecontainerapps.io"

  diagnostics = local.diagnostics
  tags        = local.tags
}
