variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "container_apps" {
  type = map(object({
    max_cpu = optional(number, 10)
    max_mem = optional(number, 2)
  }))
  default = {}
}

variable "container_app_jobs" {
  type    = map(object({}))
  default = {}
}

variable "frontdoor" {
  type        = map(string)
  default     = {}
  description = "Name and ID pairs for FrontDoor profiles"
}

variable "webtest" {
  type        = map(string)
  default     = {}
  description = "Name and domain pairs for Web Test"
}

variable "mysql" {
  type        = map(string)
  default     = {}
  description = "Name and ID pairs for MySQL"
}

variable "redis" {
  type        = map(string)
  default     = {}
  description = "Name and ID pairs for Redis"
}

variable "logicapp_metrics" {
  type = object({
    name         = string
    callback_url = string
  })
}

variable "logicapp_applogs" {
  type = object({
    name         = string
    callback_url = string
  })
}

variable "diagnostics" {
  type = object({
    storage_account_id         = string
    log_analytics_workspace_id = string
  })
}
