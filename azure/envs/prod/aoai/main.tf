terraform {
  backend "azurerm" {
    resource_group_name  = "rg-hojingpt-prod"
    storage_account_name = "sthojingptterraformprod"
    container_name       = "tfstate-aoai"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  env  = "prod"
  name = "hojingpt-${local.env}"

  tags = {
    service = "hojingpt"
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

  # network.address_space is required if creating a new VNET. Omit if referencing an existing VNET.
  cognitive_services = {
    "001" = {
      location = "eastus"
      network = {
        vnet_name     = "vnet-${local.name}-cog-001"
        address_space = ["10.200.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.200.0.0/20"] } }
      }
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "002" = {
      location = "francecentral"
      network = {
        vnet_name     = "vnet-${local.name}-cog-002"
        address_space = ["10.201.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.201.0.0/20"] } }
      }
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "003" = {
      location = "uksouth"
      network = {
        vnet_name     = "vnet-${local.name}-cog-003"
        address_space = ["10.202.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.202.0.0/20"] } }
      }
      deployments = merge(local.gpt35, local.ada002)
    }
    "004" = {
      location = "northcentralus"
      network = {
        vnet_name     = "vnet-${local.name}-cog-004"
        address_space = ["10.203.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.203.0.0/20"] } }
      }
      deployments = merge(local.gpt35, local.ada002, local.whisper)
    }
    "005" = {
      location = "australiaeast"
      network = {
        vnet_name     = "vnet-${local.name}-cog-005"
        address_space = ["10.204.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.204.0.0/20"] } }
      }
      deployments = local.gpt35
    }
    "006" = {
      location = "eastus2"
      network = {
        vnet_name     = "vnet-${local.name}-cog-006"
        address_space = ["10.205.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.205.0.0/20"] } }
      }
      deployments = merge(local.gpt35, local.ada002)
    }
    "007" = {
      location = "canadaeast"
      network = {
        vnet_name     = "vnet-${local.name}-cog-007"
        address_space = ["10.206.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.206.0.0/20"] } }
      }
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "008" = {
      location = "swedencentral"
      network = {
        vnet_name     = "vnet-${local.name}-cog-008"
        address_space = ["10.207.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.207.0.0/20"] } }
      }
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "009" = {
      location = "switzerlandnorth"
      network = {
        vnet_name     = "vnet-${local.name}-cog-009"
        address_space = ["10.208.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.208.0.0/20"] } }
      }
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "010" = {
      location = "westeurope"
      network = {
        vnet_name     = "vnet-${local.name}-cog-010"
        address_space = ["10.209.0.0/16"]
        subnets       = { "subnet-${local.name}-001" = { cidrs = ["10.209.0.0/20"] } }
      }
      deployments = merge(local.ada002, local.whisper)
    }
  }
}

data "azurerm_resource_group" "main" {
  name = "rg-${local.name}"
}

data "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "main" {
  name                 = "snet-${local.name}-001"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_log_analytics_workspace" "diagnostics" {
  name                = "law-${local.name}"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_storage_account" "diagnostics" {
  name                = "st${replace(local.name, "-", "")}logs"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "link-${local.name}-cog-001"
  resource_group_name   = data.azurerm_resource_group.main.name
  virtual_network_id    = data.azurerm_virtual_network.main.id
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  registration_enabled  = false
  tags                  = local.tags
}

module "network" {
  for_each            = local.cognitive_services
  source              = "../../../modules/openai/network"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = each.value.location
  vnet_name           = each.value.network.vnet_name
  address_space       = lookup(each.value.network, "address_space", [])
  subnets             = each.value.network.subnets
  tags                = local.tags
}

module "cognitive_service" {
  for_each            = local.cognitive_services
  source              = "../../../modules/openai/cognitive"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = each.value.location
  name                = local.name
  name_suffix         = each.key
  deployments         = each.value.deployments

  network_acls = {
    ip_rules = local.allow_ips
    virtual_network_rules = [
      {
        subnet_id = module.network[each.key].subnets["subnet-${local.name}-001"].id
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
