variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "capacity" {
  type    = number
  default = 1
}

variable "family" {
  type    = string
  default = "C"
}

variable "sku_name" {
  type    = string
  default = "Standard" # Basic, Standard, Premium
}

variable "redis_version" {
  type    = string
  default = "6"
}

variable "storage_account_name" {
  type = string
}

variable "user_assigned_ids" {
  type = list(string)
}

# resource "azurerm_storage_account" "rdb_storage" {
#   name                              = var.storage_account_name
#   resource_group_name               = var.resource_group_name
#   location                          = var.location
#   account_tier                      = "Standard"
#   account_replication_type          = "LRS"
#   public_network_access_enabled     = false
# }

resource "azurerm_redis_cache" "main" {
  name                          = "redis-${var.name}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  enable_non_ssl_port           = true
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  redis_version                 = var.redis_version

  identity {
    identity_ids = var.user_assigned_ids
    type         = "UserAssigned"
  }

  # redis_configuration {
  #   rdb_backup_enabled            = true
  #   rdb_backup_frequency          = 15
  #   rdb_backup_max_snapshot_count = 1
  #   # rdb_storage_connection_string = azurerm_storage_account.rdb_storage.primary_connection_string
  #   # maxmemory_policy              = "volatile-lru"
  # }

  # lifecycle {
  #   ignore_changes = [
  #     #HACK: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_cache
  #     redis_configuration.0.rdb_storage_connection_string,
  #     redis_configuration.0.maxmemory_policy,
  #   ]
  # }
}

# data "azurerm_storage_account" "redis" {
#   name                = "sthojingptredisstage"
#   resource_group_name = var.resource_group_name
# }
