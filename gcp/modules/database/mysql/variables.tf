variable "name" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "region" {
  type = string
}

variable "tier" {
  type = string
}

variable "database_version" {
  type = string
}

variable "availability_type" {
  type        = string
  description = "REGIONAL or ZONAL"
}

variable "disk_size" {
  type    = number
  default = 100
}

variable "backup_start_time" {
  type    = string
  default = "18:00"
}

variable "backup_location" {
  type    = string
  default = "asia"
}

variable "backup_transaction_log_retention_days" {
  type    = number
  default = 7
}

variable "backup_retentions_days" {
  type    = number
  default = 7
}

variable "query_insights" {
  type = object({
    query_plans_per_minute = optional(number, 5)
    query_string_length    = optional(number, 4500)
  })
  default = {}
}

variable "allocated_ip_range" {
  type = string
}

variable "private_network" {
  type = string
}

variable "maintenance_window" {
  type = object({
    day          = optional(number, 2)
    hour         = optional(number, 18)
    update_track = optional(string, "canary")
  })
  default = {}
}

variable "database_flags" {
  type        = map(string)
  default     = {}
  description = "see: https://cloud.google.com/mysql/cloudsql-setup"
}

locals {
  default_database_flags = {
    log_output      = "FILE"
    slow_query_log  = "on"
    long_query_time = "0.5" # seconds
  }

  database_flags = merge(local.default_database_flags, var.database_flags)
}
