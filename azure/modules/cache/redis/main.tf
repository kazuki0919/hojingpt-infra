resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "redis-${var.name}-001"
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.network.vnet_id
  tags                  = var.tags
}

resource "azurerm_storage_account" "persistence" {
  name                          = "st${replace(var.name, "-", "")}redis"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  public_network_access_enabled = true  # If false, an error occurs.
  account_tier                  = "Standard"
  account_kind                  = "StorageV2"
  account_replication_type      = "GRS"

  # account_tier                      = "Premium"
  # account_kind                      = "BlockBlobStorage"
  # account_replication_type          = "ZRS"
}

resource "azurerm_redis_cache" "main" {
  name                          = "redis-${var.name}-001"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  enable_non_ssl_port           = true
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  redis_version                 = var.redis_version

  zones = var.zones

  identity {
    identity_ids = var.user_assigned_ids
    type         = "UserAssigned"
  }

  redis_configuration {
    enable_authentication           = true
    maxfragmentationmemory_reserved = var.maxfragmentationmemory_reserved
    maxmemory_delta                 = var.maxmemory_delta
    maxmemory_reserved              = var.maxmemory_reserved
    maxmemory_policy                = var.maxmemory_policy

    aof_backup_enabled              = var.aof_enabled
    aof_storage_connection_string_0 = var.aof_enabled == true ? azurerm_storage_account.persistence.primary_connection_string : null
    aof_storage_connection_string_1 = null

    rdb_backup_enabled              = var.rdb == null ? null : true
    rdb_backup_frequency            = var.rdb == null ? null : var.rdb.backup_frequency
    rdb_backup_max_snapshot_count   = var.rdb == null ? null : var.rdb.backup_max_snapshot_count
    rdb_storage_connection_string   = var.rdb == null ? null : azurerm_storage_account.persistence.primary_connection_string
  }

  dynamic "patch_schedule" {
    for_each = var.maintenance == null ? [] : [1]
    content {
      day_of_week        = var.maintenance.day_of_week
      start_hour_utc     = var.maintenance.start_hour_utc
      maintenance_window = "PT5H"
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      redis_configuration.0.rdb_storage_connection_string
    ]
  }
}

resource "azurerm_private_endpoint" "main" {
  name                = "pep-${var.name}-redis-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.network.subnet_id

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

resource "azurerm_monitor_diagnostic_setting" "main" {
  name               = "redis-${var.name}-logs-001"
  target_resource_id = azurerm_redis_cache.main.id

  storage_account_id         = var.diagnostics.storage_account_id
  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_log {
    category_group = "audit"
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }

  # HACK
  lifecycle {
    ignore_changes = [
      storage_account_id,
      log_analytics_workspace_id,
    ]
  }
}
