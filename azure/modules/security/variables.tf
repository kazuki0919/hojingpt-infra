variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kv_allow_ips" {
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

variable "tags" {
  type    = map(string)
  default = {}
}
