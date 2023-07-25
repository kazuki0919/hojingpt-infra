terraform {
  backend "azurerm" {
    resource_group_name  = "rg-hojingpt-stage"
    storage_account_name = "sthojingptterraformstage"
    container_name       = "tfstate-aoai"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  env = "stage"

  tags = {
    service = "hojingpt"
    env     = local.env
  }

  cognitive_services = {
    "001" = {
      location = "eastus"
      network = {
        address_space = ["10.200.0.0/16"]
        subnets = {
          "subnet-hojingpt-${local.env}-001" = {
            cidrs = ["10.0.0.0/24"]
          }
        }
      }
      deployments = {
        gpt35turbo0301001 = {
          model_name    = "gpt-35-turbo"
          model_version = "0301"
        }
      }
    }
    # "002" = {
    #   location = "francecentral"
    # }
    # "003" = {
    #   location = "uksouth"
    # }
    # "004" = {
    #   location = "westeurope"
    # }
    # "005" = {
    #   location = "japaneast"
    # }
  }
}

data "azurerm_resource_group" "main" {
  name = "rg-hojingpt-${local.env}"
}

data "azurerm_virtual_network" "main" {
  name                = "vnet-hojingpt-${local.env}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "main" {
  name                 = "snet-hojingpt-${local.env}-001"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

module "network" {
  for_each            = local.cognitive_services
  source              = "../../../modules/openai/network"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = each.value.location
  name                = "hojingpt-${local.env}"
  vnet_name           = lookup(each.value.network, "name", null)
  address_space       = lookup(each.value.network, "address_space", [])
  subnets             = each.value.network.subnets
  tags                = local.tags
}

# module "cognitive_service" {
#   for_each            = local.cognitive_services
#   source              = "../../../modules/openai/cognitive"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location            = each.value.location
#   name                = "hojingpt-${local.env}"
#   name_suffix         = each.key
#   deployments         = each.value.deployments

#   network_acls = {
#     default_action = "Allow"
#     ip_rules = [
#       "150.249.202.236/32", # givery's office 8F
#       "150.249.192.10/32",  # givery's office 7F
#     ]
#     virtual_network_rules = {
#       subnet_id                            = module.network.
#       ignore_missing_vnet_service_endpoint = true
#     }
#   }

#   private_endpoint = {
#     id        = data.azurerm_virtual_network.main.id
#     subnet_id = data.azurerm_subnet.main.id
#     location  = data.azurerm_virtual_network.main.location
#   }

#   private_dns_zone = {
#     name = azurerm_private_dns_zone.main.name
#     id   = azurerm_private_dns_zone.main.id
#   }

#   tags = local.tags
# }
