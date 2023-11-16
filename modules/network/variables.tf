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

variable "subnet_app" {
  type = object({
    name  = string
    cidrs = list(string)
  })
}

variable "subnet_mysql" {
  type = object({
    name  = string
    cidrs = list(string)
  })
}

variable "subnet_bastion" {
  type = object({
    cidrs = list(string)
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
