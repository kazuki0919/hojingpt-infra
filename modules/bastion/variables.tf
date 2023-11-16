variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "bastion_subnet_id" {
  type = string
}

variable "vm_subnet_id" {
  type = string
}

variable "diagnostics" {
  type = object({
    log_analytics_workspace_id = string
    storage_account_id         = string
  })
}

variable "ssh_key" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
