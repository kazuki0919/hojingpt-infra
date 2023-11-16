terraform {
  backend "azurerm" {
    resource_group_name  = "rgjpezzzzzz10041"
    storage_account_name = "stshiseidogpttfprod"
    container_name       = "tfstate-aoai"
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
  env  = "prod"
  name = "shiseidogpt"

  tags = {
    service = local.name
    env     = local.env
    created = "givery"
  }

  vnet = {
    name = "vnjpeazrxxx00001"
    id   = "/subscriptions/cb4c9bde-f029-45e3-be3f-97359462fbcd/resourceGroups/rgjpexxxxxx00001/providers/Microsoft.Network/virtualNetworks/vnjpeazrxxx00001"
    subnets = {
      app = {
        id = "/subscriptions/cb4c9bde-f029-45e3-be3f-97359462fbcd/resourceGroups/rgjpexxxxxx00001/providers/Microsoft.Network/virtualNetworks/vnjpeazrxxx00001/subnets/snjpeintins00014"
      }
    }
  }

  gpt35 = {
    model0001 = {
      model_name    = "gpt-35-turbo"
      model_version = "0613"
    }
    model0002 = {
      model_name    = "gpt-35-turbo-16k"
      model_version = "0613"
    }
  }

  gpt4 = {
    model0003 = {
      model_name    = "gpt-4"
      model_version = "0613"
    }
    model0004 = {
      model_name    = "gpt-4-32k"
      model_version = "0613"
    }
  }

  ada002 = {
    model1001 = {
      model_name    = "text-embedding-ada-002"
      model_version = "2"
    }
  }

  whisper = {
    # TODO:
    # model2001 = {
    #   model_name    = "whisper"
    #   model_version = "001"
    # }
  }

  # Shiseido does not use VNet.
  cognitive_services = {
    "001" = {
      location    = "eastus"
      deployments = merge(local.gpt35, /*local.gpt4,*/ local.ada002)  #gpt4選べない
    }
    "002" = {
      location    = "francecentral"
      deployments = merge(/*local.gpt35,*/ local.gpt4, local.ada002) #gpt35-turbo-16k残量ない
    }
    "003" = {
      location    = "uksouth"
      deployments = merge(/*local.gpt35,*/local.gpt4, local.ada002)
    }
    "004" = {
      location    = "northcentralus"
      deployments = merge(local.gpt35, local.ada002, local.whisper)
    }
    "005" = {
      location    = "australiaeast"
      deployments = local.gpt35
    }
    "006" = {
      location    = "eastus2"
      deployments = merge(local.gpt35, local.ada002)
      deployments = {}
    }
    "007" = {
      location    = "canadaeast"
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "008" = {
      location    = "swedencentral"
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "009" = {
      location    = "switzerlandnorth"
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "010" = {
      location    = "westeurope"
      deployments = merge(local.ada002, local.whisper)
    }
  }
}

data "azurerm_resource_group" "main" {
  name = "rgjpezzzzzz10041"
}

data "azurerm_log_analytics_workspace" "diagnostics" {
  name                = "law-${local.name}-${local.env}"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_storage_account" "diagnostics" {
  name                = "st${replace("${local.name}-${local.env}", "-", "")}logs"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_private_dns_zone" "main" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
}

# TODO: 作成権限がないので後で作成する
# resource "azurerm_private_dns_zone_virtual_network_link" "main" {
#   name                  = "link-${local.name}-${local.env}-cog-001"
#   resource_group_name   = data.azurerm_resource_group.main.name
#   virtual_network_id    = local.vnet.id
#   private_dns_zone_name = data.azurerm_private_dns_zone.main.name
#   registration_enabled  = false
#   tags                  = local.tags
# }

module "cognitive_service" {
  for_each            = local.cognitive_services
  source              = "../../../../modules/openai/cognitive"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = each.value.location
  name                = "${local.name}-${local.env}"
  name_suffix         = each.key
  deployments         = each.value.deployments

  private_endpoint = {
    subnet_id   = local.vnet.subnets.app.id
    location    = data.azurerm_resource_group.main.location
    dns_zone_id = data.azurerm_private_dns_zone.main.id
  }

  diagnostics = {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.diagnostics.id
    storage_account_id         = data.azurerm_storage_account.diagnostics.id
  }

  tags = local.tags
}
