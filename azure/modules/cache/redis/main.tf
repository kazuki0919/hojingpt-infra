# resource "azurerm_storage_account" "rdb_storage" {
#   name                              = var.storage_account_name
#   resource_group_name               = var.resource_group_name
#   location                          = var.location
#   account_tier                      = "Standard"
#   account_replication_type          = "LRS"
#   public_network_access_enabled     = false
# }

resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_endpoint" "main" {
  name                = "pep-${var.name}-redis-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.main.id]
  }

  private_service_connection {
    name                           = "default"
    private_connection_resource_id = azurerm_redis_cache.main.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }
}

resource "azurerm_redis_cache" "main" {
  name                          = "redis-${var.name}-001"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  enable_non_ssl_port           = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  redis_version                 = var.redis_version

  identity {
    identity_ids = var.user_assigned_ids
    type         = "UserAssigned"
  }

  # subnet_id = var.subnet_id

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
