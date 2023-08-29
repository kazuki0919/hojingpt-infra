variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "name" {
  type = string
}

variable "container" {
  type = object({
    app_name        = string
    aoai_name       = string
    subnet_id       = string
    lb_frontend_ids = list(string)
  })
}

variable "custom_domains" {
  type = map(object({
    host_name   = string
    dns_zone_id = optional(string, null)
  }))
  default = {}
}

variable "sku_name" {
  type    = string
  default = "Premium_AzureFrontDoor"
}

variable "response_timeout_seconds" {
  type    = number
  default = 240
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
