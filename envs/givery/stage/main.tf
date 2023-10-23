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
  env = "stage"

  domains = [
    "staging.hojingpt.com",
    "staging-azure.hojingpt.com",
    # "staging.hojingai.com",
    # "staging-azure.hojingai.com",
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
  address_space       = ["10.0.0.0/16"]

  subnet_app = {
    name  = "snet-hojingpt-${local.env}-001"
    cidrs = ["10.0.0.0/23"]
  }

  subnet_mysql = {
    name  = "snet-hojingpt-${local.env}-002"
    cidrs = ["10.0.2.0/24"]
  }

  subnet_bastion = {
    cidrs = ["10.0.3.0/24"]
  }

  tags = local.tags
}

module "logging" {
  source                   = "../../../modules/logging"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  name                     = "hojingpt-${local.env}"
  storage_replication_type = "GRS" # TODO: Would like to switch to ZRS if possible...
  tags                     = local.tags
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

  diagnostics = module.logging.diagnostics
  tags        = local.tags

  # TODO: Delete when persistence is no longer required.
  sku_name                        = "Premium"
  family                          = "P"
  capacity                        = 1
  maxfragmentationmemory_reserved = 627
  maxmemory_delta                 = 627
  maxmemory_reserved              = 627
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

  storage = {
    iops    = 360
    size_gb = 20
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
  resource_group_name = "mc_purplewater-a7ff9cea-rg_purplewater-a7ff9cea_japaneast"
}

module "frontdoor" {
  source              = "../../../modules/frontdoor"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "houjingpt-${local.env}-jpeast"

  container = {
    app_name        = "hojingpt-${local.env}-001"
    aoai_name       = "hojingpt-${local.env}-002"
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
  }

  mysql = {
    "${module.mysql.main.name}" = module.mysql.main.id
  }

  redis = {
    "${module.redis.main.name}" = module.redis.main.id
  }

  logicapp_metrics = {
    name         = "la-hojingpt-${local.env}-metrics-alert"
    callback_url = "https://prod-09.japaneast.logic.azure.com:443/workflows/646aec02cc574ab99878716304c90cea/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=g2NurfeYoEzn0FfAEt2Q8p9r8l9CAA-Lc51VlB9B7Yk"
  }

  logicapp_applogs = {
    name         = "la-hojingpt-${local.env}-applogs-alert"
    callback_url = "https://prod-07.japaneast.logic.azure.com:443/workflows/f25d2cc7d66a49be971b9809441ee94d/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=dmimCaz4L7bumtmOmrML75GR4yS50KBR3ufATiYRGxg"
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
    subnet_id               = module.network.subnet_app.id
    allow_ips               = local.allow_ips
    private_link_access_ids = [for s in module.search : s.id]
  }
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

module "search" {
  for_each            = toset(["001"])
  source              = "../../../modules/openai/search"
  name                = "hojingpt-${local.env}"
  name_suffix         = each.key
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allow_ips           = local.allow_ips
  tags                = local.tags

  private_endpoint = {
    subnet_id   = module.network.subnet_app.id
    location    = data.azurerm_resource_group.main.location
    dns_zone_id = azurerm_private_dns_zone.search.id
  }
}
