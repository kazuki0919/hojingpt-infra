variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kv_allow_cidrs" {
  type    = list(string)
  default = []
}

variable "kv_users" {
  type    = map(string)
  default = {}
}

variable "kv_subnets" {
  type    = list(string)
  default = []
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
