variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "name" {
  type = string
}

variable "container_app" {
  type = object({
    name            = string
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

variable "health" {
  type = object({
    path                = optional(string, "/sys/health")
    request_type        = optional(string, "GET")
    protocol            = optional(string, "Http")
    interval_in_seconds = optional(number, 60)
  })
  default = {}
}

variable "sku_name" {
  type    = string
  default = "Premium_AzureFrontDoor"
}

variable "response_timeout_seconds" {
  type    = number
  default = 60
}

variable "tags" {
  type    = map(string)
  default = {}
}
