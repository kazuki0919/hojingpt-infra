variable "name" {
  type = string
}

variable "registory_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "user_assigned_ids" {
  type = list(string)
}

variable "load_balancer_frontend_ip_configuration_ids" {
  type    = list(string)
  default = []
}

variable "subnet_id" {
  type = string
}

variable "key_vault_object_id" {
  type = string
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
