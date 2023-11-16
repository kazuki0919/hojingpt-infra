terraform {
  backend "azurerm" {
    resource_group_name  = "rgjpezzzzzz10041"
    storage_account_name = "stshiseidogpttfprod"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  # HACK: Workaround for per-subscription resource provider registration errors
  # see: https://blog.shibayan.jp/entry/20210107/1609948542
  skip_provider_registration = true
}

locals {
  env     = "prod"
  name    = "shiseidogpt"
  domains = ["shiseido.hojingpt.com"]

  allow_ips = [
    "222.230.117.190", # yusuke.yoda's home IP. To be removed at a later.
    "150.249.202.236", # givery's office 8F
    "150.249.192.10",  # givery's office 7F
  ]

  allow_cidrs = [for ip in local.allow_ips : "${ip}/32"]

  users = {
    "86343274-cdd1-4e63-b280-ae7587d1b425" = "yusuke.yoda@givery.onmicrosoft.com"
  }

  vnet = {
    name = "vnjpeazrxxx00001"
    id   = "/subscriptions/cb4c9bde-f029-45e3-be3f-97359462fbcd/resourceGroups/rgjpexxxxxx00001/providers/Microsoft.Network/virtualNetworks/vnjpeazrxxx00001"
    subnets = {
      app = {
        id = "/subscriptions/cb4c9bde-f029-45e3-be3f-97359462fbcd/resourceGroups/rgjpexxxxxx00001/providers/Microsoft.Network/virtualNetworks/vnjpeazrxxx00001/subnets/snjpeintins00014"
      }
      mysql = {
        id = "/subscriptions/cb4c9bde-f029-45e3-be3f-97359462fbcd/resourceGroups/rgjpexxxxxx00001/providers/Microsoft.Network/virtualNetworks/vnjpeazrxxx00001/subnets/snjpeintsql00012"
      }
    }
  }

  tags = {
    service = local.name
    env     = local.env
    created = "givery"
  }
}

data "azurerm_resource_group" "main" {
  name = "rgjpezzzzzz10041"
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
    local.vnet.subnets.app.id,
    local.vnet.subnets.mysql.id,
  ]

  diagnostics = module.logging.diagnostics
  tags        = local.tags
}

# module "redis" {
#   source              = "../../../modules/cache/redis"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   name                = "${local.name}-${local.env}"
#   user_assigned_ids   = [module.security.user_assigned_identity.id]

#   network = {
#     vnet_id   = local.vnet.id
#     subnet_id = local.vnet.subnets.app.id
#   }

#   sku_name                        = "Premium"
#   family                          = "P"
#   capacity                        = 1
#   zones                           = ["1", "2"]
#   maxfragmentationmemory_reserved = 642
#   maxmemory_delta                 = 642
#   maxmemory_reserved              = 642

#   rdb = {
#     backup_frequency          = 60
#     backup_max_snapshot_count = 1
#   }

#   # Tue 01:00-06:00 JST
#   maintenance = {
#     day_of_week    = "Monday"
#     start_hour_utc = 16
#   }

#   persistence_storage_creation = false
#   diagnostics = module.logging.diagnostics
#   tags        = local.tags
# }

# module "mysql" {
#   source              = "../../../modules/database/mysql"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   name                = "${local.name}-${local.env}"
#   key_vault_id        = module.security.key_vault.id
#   db_name             = "hojingpt"
#   administrator_login = "hojingpt"

#   network = {
#     vnet_id   = local.vnet.id
#     subnet_id = local.vnet.subnets.mysql.id
#   }

#   sku_name = "MO_Standard_E4ads_v5"

#   high_availability = {
#     mode = "ZoneRedundant"
#   }

#   storage = {
#     iops    = 684
#     size_gb = 128
#   }

#   # Tue 03:00-04:00 JST
#   maintenance = {
#     day_of_week  = 1
#     start_hour   = 18
#     start_minute = 0
#   }

#   diagnostics = module.logging.diagnostics
#   tags        = local.tags
# }

# module "app" {
#   source              = "../../../modules/app"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = data.azurerm_resource_group.main.location
#   name                = "${local.name}-${local.env}"
#   registory_name      = "cr${local.name}${local.env}"
#   user_assigned_ids   = [module.security.user_assigned_identity.id]
#   subnet_id           = data.data.azurerm_subnet.main["app"].id
#   key_vault_object_id = module.security.key_vault_access_policy.object_id
#   diagnostics         = module.logging.diagnostics
#   tags                = local.tags
# }

# data "azurerm_lb" "kubernetes_internal" {
#   name                = "kubernetes-internal"
#   resource_group_name = "TODO"
# }

module "frontdoor" {
  source              = "../../../modules/frontdoor"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  name                = "${local.name}-${local.env}-jpeast"

  # container = {
  #   app_name        = "${local.name}-${local.env}-001"
  #   blob_name       = "${local.name}-${local.env}-003"
  #   subnet_id       = local.vnet.subnets.app.id
  #   lb_frontend_ids = data.azurerm_lb.kubernetes_internal.frontend_ip_configuration.*.id
  # }

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
    # "ca-${local.name}-${local.env}-001" = {}
  }

  mysql = {
    # "${module.mysql.main.name}" = module.mysql.main.id
  }

  redis = {
    # "${module.redis.main.name}" = module.redis.main.id
  }

  # TODO:
  # webtest = {
  #   "default" = "https://aozorabank.hojingpt.com/sys/health"
  # }

  logicapp_metrics = {
    name         = "la-${local.name}-${local.env}-metrics-alert"
    callback_url = "https://prod-04.japaneast.logic.azure.com:443/workflows/ae64dd75d4a943e2bd9e3d6e3058c869/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=EHslw2e8MDOageArjsq34LprzO3-c8Fos4QIIWAoVuo"
  }

  logicapp_applogs = {
    name         = "la-${local.name}-${local.env}-applogs-alert"
    callback_url = "https://prod-13.japaneast.logic.azure.com:443/workflows/886d1833c7cf48fa99326d160acfc9f5/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=V0a-esr7jKKaC_iU7Rqkkw0xQEd8PzTug0dlBADsxVU"
  }

  tags = local.tags
}
