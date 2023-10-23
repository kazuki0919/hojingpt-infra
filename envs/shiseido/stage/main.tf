terraform {
  backend "azurerm" {
    resource_group_name  = "rg-shiseidogpt-stage"
    storage_account_name = "stshiseidogpttfstage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  env     = "stage"
  name    = "shiseidogpt"
  domains = ["staging.aozorabank.hojingpt.com"]

  allow_ips = [
    "222.230.117.190", # yusuke.yoda's home IP. To be removed at a later.
    "150.249.202.236", # givery's office 8F
    "150.249.192.10",  # givery's office 7F
  ]

  allow_cidrs = [for ip in local.allow_ips : "${ip}/32"]

  users = {
    "TODO" = "yusuke.yoda@givery.onmicrosoft.com"
  }

  tags = {
    service = local.name
    env     = local.env
  }
}

data "azurerm_resource_group" "main" {
  name = "rg-${local.name}-${local.env}"
}

data "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name}-${local.env}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "main" {
  for_each = {
    app   = "snet-${local.name}-${local.env}-001"
    mysql = "snet-${local.name}-${local.env}-002"
  }
  name                 = each.value
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

module "logging" {
  source              = "../../../modules/logging"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
  tags                = local.tags
}

module "security" {
  source              = "../../../modules/security"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
  kv_allow_cidrs      = local.allow_cidrs
  kv_users            = local.users

  kv_subnets = [
    data.data.azurerm_subnet.main["app"].id,
    data.data.azurerm_subnet.main["mysql"].id,
  ]

  diagnostics = module.logging.diagnostics
  tags        = local.tags
}

module "redis" {
  source              = "../../../modules/cache/redis"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}"
  user_assigned_ids   = [module.security.user_assigned_identity.id]

  network = {
    vnet_id   = data.azurerm_virtual_network.main.id
    subnet_id = data.data.azurerm_subnet.main["app"].id
  }

  diagnostics = module.logging.diagnostics
  tags        = local.tags

  # TODO: Delete when persistence is no longer required.
  sku_name                        = "Premium"
  family                          = "P"
  capacity                        = 1
  maxfragmentationmemory_reserved = 642
  maxmemory_delta                 = 642
  maxmemory_reserved              = 642
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
    vnet_id   = data.azurerm_virtual_network.main.id
    subnet_id = data.data.azurerm_subnet.main["mysql"].id
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
  name                = "${local.name}-${local.env}"
  registory_name      = "cr${local.name}${local.env}"
  user_assigned_ids   = [module.security.user_assigned_identity.id]
  subnet_id           = data.data.azurerm_subnet.main["app"].id
  key_vault_object_id = module.security.key_vault_access_policy.object_id
  diagnostics         = module.logging.diagnostics
  tags                = local.tags
}

data "azurerm_lb" "kubernetes_internal" {
  name                = "kubernetes-internal"
  resource_group_name = "TODO"
}

module "frontdoor" {
  source              = "../../../modules/frontdoor"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}-jpeast"

  container = {
    app_name        = "${local.name}-${local.env}-001"
    subnet_id       = data.data.azurerm_subnet.main["app"].id
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

  logicapp_metrics = {
    name         = "la-${local.name}-${local.env}-metrics-alert"
    callback_url = "https://prod-06.japaneast.logic.azure.com:443/workflows/86996c9c187048a48aa15b0ef2a14aa3/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=Oi6zwxFRECxbNO_GimuEQrBtzRJBGzotyHQ0LImZ5hw"
  }

  logicapp_applogs = {
    name         = "la-${local.name}-${local.env}-applogs-alert"
    callback_url = "https://prod-07.japaneast.logic.azure.com:443/workflows/e13637f5d4354f02b9a2c43f71a53db1/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=L2qgS5TASfyitgGnjuEdfRKzS5cyhiCtoF0Q0wMzktE"
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
