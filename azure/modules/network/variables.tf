variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "app" {
  type = object({
    cidrs = list(string)
  })
}

variable "mysql" {
  type = object({
    cidrs = list(string)
  })
}

variable "bastion" {
  type = object({
    cidrs     = list(string)
    allow_ips = list(string)
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
