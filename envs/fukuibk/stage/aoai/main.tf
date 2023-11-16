terraform {
  backend "azurerm" {
    resource_group_name  = "rg-aozoragpt-stage"
    storage_account_name = "staozoragpttfstage"
    container_name       = "tfstate-aoai"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  env  = "stage"
  name = "aozoragpt"

  tags = {
    service = local.name
    env     = local.env
  }

  allow_ips = [
    "222.230.117.190", # yusuke.yoda's home IP. To be removed at a later.
    "150.249.202.236", # givery's office 8F
    "150.249.192.10",  # givery's office 7F
  ]

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

  # 001 to 009 are already reserved.
  cognitive_services = {
    "011" = {
      location = "japaneast"
      network = {
        vnet_name = "vnet-${local.name}-${local.env}-001"
        subnets = {
          "snet-${local.name}-${local.env}-003" = {
            cidrs = ["10.0.4.0/24"]
          }
        }
      }
      deployments = merge(
        local.gpt35,
        # local.gpt4, Not Available now...
        local.ada002,
        local.whisper
      )
    }
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
  name                 = "snet-${local.name}-${local.env}-001"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_log_analytics_workspace" "diagnostics" {
  name                = "law-${local.name}-${local.env}"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_storage_account" "diagnostics" {
  name                = "st${replace("${local.name}-${local.env}", "-", "")}logs"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "link-${local.name}-${local.env}-cog-001"
  resource_group_name   = data.azurerm_resource_group.main.name
  virtual_network_id    = data.azurerm_virtual_network.main.id
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  registration_enabled  = false
  tags                  = local.tags
}

module "network" {
  for_each            = local.cognitive_services
  source              = "../../../../modules/openai/network"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = each.value.location
  vnet_name           = each.value.network.vnet_name
  address_space       = lookup(each.value.network, "address_space", [])
  subnets             = each.value.network.subnets
  tags                = local.tags
}

module "cognitive_service" {
  for_each            = local.cognitive_services
  source              = "../../../../modules/openai/cognitive"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = each.value.location
  name                = "${local.name}-${local.env}"
  name_suffix         = each.key
  deployments         = each.value.deployments

  network_acls = {
    ip_rules = local.allow_ips
    virtual_network_rules = [
      {
        subnet_id = module.network[each.key].subnets["snet-${local.name}-${local.env}-003"].id
      }
    ]
  }

  private_endpoint = {
    subnet_id   = data.azurerm_subnet.main.id
    location    = data.azurerm_virtual_network.main.location
    dns_zone_id = azurerm_private_dns_zone.main.id
  }

  diagnostics = {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.diagnostics.id
    storage_account_id         = data.azurerm_storage_account.diagnostics.id
  }

  tags = local.tags
}
