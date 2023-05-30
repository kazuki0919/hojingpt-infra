variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "network" {
  type = object({
    vnet_id   = string
    subnet_id = string
  })
}

variable "sku_name" {
  type = string
}

variable "db_version" {
  type = string
}

variable "db_name" {
  type = string
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "zone" {
  type    = string
  default = "1"
}

variable "storage" {
  type = object({
    iops    = number
    size_gb = number
  })
}

variable "key_vault_id" {
  type = string
}

variable "administrator_login" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
