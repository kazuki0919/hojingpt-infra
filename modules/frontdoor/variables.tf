variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "name" {
  type = string
}

variable "profile_id" {
  type    = string
  default = null
}

variable "container" {
  type = object({
    app_name        = optional(string, null)
    aoai_name       = optional(string, null)
    blob_name       = optional(string, null)
    subnet_id       = optional(string, null)
    lb_frontend_ids = optional(list(string), [])
  })
  default = {}
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

variable "default_rule_set_name" {
  type    = string
  default = "DefaultRuleSet"
}

variable "waf_enabled" {
  type    = bool
  default = true
}

variable "waf_mode" {
  type        = string
  default     = "Detection"
  description = "Valid value are 'Detection' or 'Prevention'. The default is Detection"
}

variable "waf_allow_cidrs" {
  type    = list(string)
  default = []
}

variable "diagnostics" {
  type = object({
    log_analytics_workspace_id = string
    storage_account_id         = string
  })
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
