variable "app_name" {
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
  type = list(string)
}

variable "subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
