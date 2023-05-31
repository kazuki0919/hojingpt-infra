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

variable "storage_account_name" {
  type = string
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

variable "rds" {
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

variable "tags" {
  type    = map(string)
  default = {}
}
