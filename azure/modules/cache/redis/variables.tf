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
  default = "C" # C = Basic, Standard, P = Premium
}

variable "sku_name" {
  type    = string
  default = "Basic" # Basic, Standard, Premium
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

variable "subnet_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
