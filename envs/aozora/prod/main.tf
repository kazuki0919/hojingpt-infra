terraform {
  backend "azurerm" {
    resource_group_name  = "rg-aozoragpt-prod"
    storage_account_name = "staozoragpttfprod"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  env     = "prod"
  name    = "aozoragpt"
  domains = ["aozorabank.hojingpt.com"]

  allow_ips = [
    "222.230.117.190", # yusuke.yoda's home IP. To be removed at a later.
    "150.249.202.236", # givery's office 8F
    "150.249.192.10",  # givery's office 7F
  ]

  allow_cidrs = [for ip in local.allow_ips : "${ip}/32"]

  # TODO: IP 制限をかけようとしたら SSO ログインできなくなったので無効化。顧客としては制限かけてほしいとのことなので、どうするか要検討
  allow_cidrs_for_waf = [
    # "150.249.192.10/32",  # givery's office 7F
    # "150.249.202.236/32", # givery's office 8F
    # "210.188.173.0/24",   # aozorabank's office
    # "210.175.30.0/24",    # aozorabank's office (TODO: 2024/3までにIPが変更される予定なので、依頼が来たら対応する)
  ]

  users = {
    "22fa63f9-94d8-4a82-a7b1-e9c5e8b43e9b" = "yusuke.yoda@givery.onmicrosoft.com"
  }

  tags = {
    service = local.name
    env     = local.env
  }
}

data "azurerm_resource_group" "main" {
  name = "rg-${local.name}-${local.env}"
}

module "network" {
  source              = "../../../modules/network"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
  address_space       = ["10.1.0.0/16"]

  subnet_app = {
    name  = "snet-${local.name}-${local.env}-001"
    cidrs = ["10.1.0.0/20"]
  }

  subnet_mysql = {
    name  = "snet-${local.name}-${local.env}-002"
    cidrs = ["10.1.16.0/24"]
  }

  subnet_bastion = {
    cidrs = ["10.1.17.0/24"]
  }

  tags = local.tags
}

module "logging" {
  source              = "../../../modules/logging"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
  tags                = local.tags
  retention_in_days   = 730
}

module "security" {
  source              = "../../../modules/security"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
  kv_allow_cidrs      = local.allow_cidrs
  kv_users            = local.users

  kv_subnets = [
    module.network.subnet_app.id,
    module.network.subnet_mysql.id,
  ]

  diagnostics = module.logging.diagnostics
  tags        = local.tags
}

module "bastion" {
  source              = "../../../modules/bastion"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
  ssh_key             = "ssh-${local.name}-${local.env}-001"
  bastion_subnet_id   = module.network.subnet_bastion.id
  vm_subnet_id        = module.network.subnet_app.id
  diagnostics         = module.logging.diagnostics
  tags                = local.tags
}

# TODO: Build if need
# module "batch" {
#   source              = "../../../modules/batch"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   name                = "${local.name}-${local.env}"
#   ssh_key             = "ssh-${local.name}-${local.env}-001"
#   subnet_id           = module.network.subnet_app.id
#   tags                = local.tags
# }

module "redis" {
  source              = "../../../modules/cache/redis"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
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

  diagnostics = module.logging.diagnostics
  tags        = local.tags
}

module "mysql" {
  source              = "../../../modules/database/mysql"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
  key_vault_id        = module.security.key_vault.id
  db_name             = "hojingpt"
  administrator_login = "hojingpt"

  network = {
    vnet_id   = module.network.vnet.id
    subnet_id = module.network.subnet_mysql.id
  }

  sku_name = "MO_Standard_E4ads_v5"

  high_availability = {
    mode                      = "ZoneRedundant"
    # standby_availability_zone = "3"
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

  diagnostics = module.logging.diagnostics
  tags        = local.tags
}

module "app" {
  source              = "../../../modules/app"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
  registory_name      = "cr${local.name}${local.env}"
  user_assigned_ids   = [module.security.user_assigned_identity.id]
  subnet_id           = module.network.subnet_app.id
  key_vault_object_id = module.security.key_vault_access_policy.object_id
  diagnostics         = module.logging.diagnostics
  tags                = local.tags
}

data "azurerm_lb" "kubernetes_internal" {
  name                = "kubernetes-internal"
  resource_group_name = "MC_thankfulriver-5d6eca4c-rg_thankfulriver-5d6eca4c_japaneast"
}

module "frontdoor" {
  source              = "../../../modules/frontdoor"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}-jpeast"

  container = {
    app_name        = "${local.name}-${local.env}-001"
    subnet_id       = module.network.subnet_app.id
    lb_frontend_ids = data.azurerm_lb.kubernetes_internal.frontend_ip_configuration.*.id
  }

  custom_domains = {
    for domain in local.domains : "${replace(domain, ".", "-")}" => {
      host_name = domain
    }
  }

  waf_mode        = length(local.allow_cidrs_for_waf) > 0 ? "Prevention" : "Detection"
  waf_allow_cidrs = local.allow_cidrs_for_waf

  diagnostics = module.logging.diagnostics
  tags        = local.tags
}

module "monitoring" {
  source              = "../../../modules/monitoring"
  name                = "${local.name}-${local.env}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  diagnostics         = module.logging.diagnostics

  container_apps = {
    "ca-${local.name}-${local.env}-001" = {}
  }

  mysql = {
    "${module.mysql.main.name}" = module.mysql.main.id
  }

  redis = {
    "${module.redis.main.name}" = module.redis.main.id
  }

  # TODO:
  # webtest = {
  #   "default" = "https://aozorabank.hojingpt.com/sys/health"
  # }

  logicapp_metrics = {
    name         = "la-${local.name}-${local.env}-metrics-alert"
    callback_url = "https://prod-11.japaneast.logic.azure.com:443/workflows/7283b7b3ea8a4ab5bd8758ce071387e9/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=CFOyu7Sk40EpSKtwIFsqSKWxFcmicXFCfxzJWD_lg4g"
  }

  logicapp_applogs = {
    name         = "la-${local.name}-${local.env}-applogs-alert"
    callback_url = "https://prod-04.japaneast.logic.azure.com:443/workflows/63508fc74fd74551a2fd85f5f0926e04/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=MQMx3yS0-WPf9jrulLjOzSjYkkMO5U4rxrfqv6IszHI"
  }

  tags = local.tags
}

module "mail" {
  source              = "../../../modules/mail"
  name                = "${local.name}-${local.env}"
  resource_group_name = data.azurerm_resource_group.main.name
  diagnostics         = module.logging.diagnostics
  tags                = local.tags
}
