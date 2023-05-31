variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "name" {
  type = string
}

variable "app" {
  type = object({
    name                   = string
    # host                   = string
    # private_link_target_id = string
  })
}

variable "subnet_id" {
  type = string
}

variable "domain" {
  type = object({
    name        = string
    host_name   = string
    dns_zone_id = string
  })
}

variable "sku_name" {
  type    = string
  default = "Premium_AzureFrontDoor" # or Standard_AzureFrontDoor
}

variable "waf_policy_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
