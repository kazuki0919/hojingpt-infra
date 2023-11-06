terraform {
  backend "azurerm" {
    resource_group_name  = "rgjpezzzzzz10041"
    storage_account_name = "stshiseidogpttfshared"
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
  env     = "shared"
  name    = "shiseidogpt"

  tags = {
    service = local.name
    env     = local.env
    created = "givery"
  }
}

data "azurerm_resource_group" "main" {
  name = "rgjpezzzzzz10041"
}

resource "azurerm_private_dns_zone" "mysql" {
  name                = "private.mysql.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}
