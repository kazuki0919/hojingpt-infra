terraform {
  backend "azurerm" {
    resource_group_name  = "rg-shiseidogpt-prod"
    storage_account_name = "stshiseidogpttfprod"
    container_name       = "tfstate-aoai"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  env  = "prod"
  name = "shiseidogpt"

  tags = {
    service = local.name
    env     = local.env
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
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "002" = {
      location    = "francecentral"
      deployments = merge(local.gpt35, local.gpt4, local.ada002)
    }
    "003" = {
      location    = "uksouth"
      deployments = merge(local.gpt35, local.ada002)
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

module "cognitive_service" {
  for_each            = local.cognitive_services
  source              = "../../../../modules/openai/cognitive"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = each.value.location
  name                = "${local.name}-${local.env}"
  name_suffix         = each.key
  deployments         = each.value.deployments

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
