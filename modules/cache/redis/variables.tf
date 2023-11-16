variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "Basic" # Basic, Standard, Premium
}

variable "family" {
  type    = string
  default = "C" # C = Basic, Standard, P = Premium
}

variable "capacity" {
  type    = number
  default = 0
}

variable "redis_version" {
  type    = string
  default = "6"
}

variable "user_assigned_ids" {
  type = list(string)
}

variable "network" {
  type = object({
    vnet_id   = string
    subnet_id = string
  })
}

variable "zones" {
  type    = list(string)
  default = null
}

variable "maxfragmentationmemory_reserved" {
  type = number
  default = 30
}

variable "maxmemory_delta" {
  type    = number
  default = 30
}

variable "maxmemory_reserved" {
  type    = number
  default = 30
}

variable "maxmemory_policy" {
  type    = string
  default = "volatile-lru"
}

variable "persistence_storage_creation" {
  type    = bool
  default = true
}

variable "rdb" {
  type = object({
    backup_frequency          = number
    backup_max_snapshot_count = number
  })
  default = null
}

variable "aof_enabled" {
  type    = bool
  default = null
}

variable "maintenance" {
  type = object({
    day_of_week    = string
    start_hour_utc = number
  })
  default = null
}

variable "private_dns_zone" {
  type = object({
    name = string
    id   = string
  })
  default = null
}

variable "diagnostics" {
  type = object({
    log_analytics_workspace_id = string
    storage_account_id         = string
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "storage_replication_type" {
  type    = string
  default = "ZRS"
}
