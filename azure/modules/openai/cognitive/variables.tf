variable "name" {
  type = string
}

variable "name_suffix" {
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

variable "network_acls" {
  type = object({
    default_action = optional(string, "Deny")
    ip_rules       = optional(list(string), [])

    virtual_network_rules = list(object({
      subnet_id                            = string
      ignore_missing_vnet_service_endpoint = optional(bool, false)
    }))
  })
  default = null
}

variable "private_endpoint" {
  type = object({
    id        = string
    subnet_id = string
    location  = string

    dns_zone = object({
      name = string
      id   = string
    })
  })
  default = null
}

variable "deployments" {
  type = map(object({
    model_name      = string
    model_version   = string
    model_format    = optional(string, "OpenAI")
    rai_policy_name = optional(string, "Microsoft.Default")
    scale_type      = optional(string, "Standard")
    scale_capacity  = optional(number, 1)
  }))
}
