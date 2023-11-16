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
    "azure.hojingpt.com",
    "hojingai.com",
    # "azure.hojingai.com",
  ]

  allow_ips = [
    "222.230.117.190", # yusuke.yoda's home IP. To be removed at a later.
    "150.249.202.236", # givery's office 8F
    "150.249.192.10",  # givery's office 7F
  ]

  allow_cidrs = [for ip in local.allow_ips : "${ip}/32"]

  users = {
    "ad94dd20-bb7f-46e6-a326-73925eef35ab" = "yusuke.yoda@givery.onmicrosoft.com"
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
  source              = "../../../modules/network"
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
  source                   = "../../../modules/logging"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  name                     = "hojingpt-${local.env}"
  tags                     = local.tags
  storage_replication_type = "GRS" # TODO: Would like to switch to ZRS if possible...
  retention_in_days        = 730
}

module "security" {
  source              = "../../../modules/security"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
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
  name                = "hojingpt-${local.env}"
  ssh_key             = "ssh-hojingpt-${local.env}-001"
  bastion_subnet_id   = module.network.subnet_bastion.id
  vm_subnet_id        = module.network.subnet_app.id
  diagnostics         = module.logging.diagnostics
  tags                = local.tags
}

module "batch" {
  source              = "../../../modules/batch"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  ssh_key             = "ssh-hojingpt-${local.env}-001"
  subnet_id           = module.network.subnet_app.id
  tags                = local.tags
}

module "redis" {
  source                   = "../../../modules/cache/redis"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  name                     = "hojingpt-${local.env}"
  user_assigned_ids        = [module.security.user_assigned_identity.id]
  storage_replication_type = "GRS" # TODO: Would like to switch to ZRS if possible...

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
  name                = "hojingpt-${local.env}"
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

  diagnostics = module.logging.diagnostics
  tags        = local.tags
}

module "app" {
  source              = "../../../modules/app"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}"
  registory_name      = "crhojingpt${local.env}"
  user_assigned_ids   = [module.security.user_assigned_identity.id]
  subnet_id           = module.network.subnet_app.id
  key_vault_object_id = module.security.key_vault_access_policy.object_id
  diagnostics         = module.logging.diagnostics
  tags                = local.tags
}

data "azurerm_lb" "kubernetes_internal" {
  name                = "kubernetes-internal"
  resource_group_name = "MC_salmonsmoke-97ec2d6e-rg_salmonsmoke-97ec2d6e_japaneast"
}

module "frontdoor" {
  source              = "../../../modules/frontdoor"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "hojingpt-${local.env}-jpeast"

  container = {
    app_name        = "hojingpt-${local.env}-001"
    aoai_name       = "hojingpt-${local.env}-002"
    blob_name       = "hojingpt-${local.env}-003"
    subnet_id       = module.network.subnet_app.id
    lb_frontend_ids = data.azurerm_lb.kubernetes_internal.frontend_ip_configuration.*.id
  }

  custom_domains = {
    for domain in local.domains : "${replace(domain, ".", "-")}" => {
      host_name = domain
    }
  }

  diagnostics = module.logging.diagnostics
  tags        = local.tags
}

module "monitoring" {
  source              = "../../../modules/monitoring"
  name                = "hojingpt-${local.env}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  diagnostics         = module.logging.diagnostics

  container_apps = {
    "ca-hojingpt-${local.env}-001" = {}
    "ca-hojingpt-${local.env}-002" = {}
    "ca-hojingpt-${local.env}-003" = {}
  }

  container_app_jobs = {
    "ca-hojingpt-${local.env}-clawler" = {}
  }

  mysql = {
    "${module.mysql.main.name}" = module.mysql.main.id
  }

  redis = {
    "${module.redis.main.name}" = module.redis.main.id
  }

  webtest = {
    "default" = "https://hojingpt.com/sys/health"
  }

  logicapp_metrics = {
    name         = "la-hojingpt-${local.env}-metrics-alert"
    callback_url = "https://prod-07.japaneast.logic.azure.com:443/workflows/accef70a4e2745b2aeb7dac7a0aa1997/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=AE3hIXhvOW8zg43Uc8eiwWM5lwrc2ODrvRFzd3HXJ9Q"
  }

  logicapp_applogs = {
    name         = "la-hojingpt-${local.env}-applogs-alert"
    callback_url = "https://prod-19.japaneast.logic.azure.com:443/workflows/457b86f3b3fa4338a985e53e4cab07cd/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=s1ERPDSEIPxAKGsqCE-4OqY40zgqncE_m_7d0b4imtk"
  }

  tags = local.tags
}

module "mail" {
  source              = "../../../modules/mail"
  name                = "hojingpt-${local.env}"
  resource_group_name = data.azurerm_resource_group.main.name
  diagnostics         = module.logging.diagnostics
  tags                = local.tags
}

module "storage" {
  source                = "../../../modules/storage"
  name                  = "hojingpt-${local.env}"
  resource_group_name   = data.azurerm_resource_group.main.name
  location              = data.azurerm_resource_group.main.location
  diagnostics           = module.logging.diagnostics
  backup_retention_days = 1
  tags                  = local.tags

  network = {
    subnet_id = module.network.subnet_app.id
    allow_ips = local.allow_ips
  }
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

locals {
  search_private_endpoint = {
    subnet_id   = module.network.subnet_app.id
    location    = data.azurerm_resource_group.main.location
    dns_zone_id = azurerm_private_dns_zone.search.id
  }
}

module "search" {
  for_each = {
    "001m" = {
      sku              = "standard",
      replica_count    = 2,
      partition_count  = 1,
      private_endpoint = local.search_private_endpoint
    }
  }
  source              = "../../../modules/openai/search"
  name                = "hojingpt-${local.env}"
  name_suffix         = each.key
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = local.tags

  sku              = each.value.sku
  replica_count    = each.value.replica_count
  partition_count  = each.value.partition_count
  private_endpoint = each.value.private_endpoint
}
