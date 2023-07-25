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
  type = set(object({
    default_action = string
    ip_rules       = optional(set(string))
    virtual_network_rules = optional(set(object({
      subnet_id                            = string
      ignore_missing_vnet_service_endpoint = optional(bool, false)
    })))
  }))
  default = null
}

variable "private_dns_zone" {
  type = object({
    name = string
    id   = string
  })
}

variable "private_endpoint" {
  type = object({
    id        = string
    subnet_id = string
    location  = string
  })
}

variable "deployments" {
  type = map(object({
    model_name      = string
    model_version   = string
    model_format    = optional(string, "OpenAI")
    rai_policy_name = optional(string, "Microsoft.Default")
    scale_type      = optional(string, "Standard")
  }))
}
