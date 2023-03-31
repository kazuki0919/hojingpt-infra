variable "name" {
  type = string
}

variable "tier" {
  type        = string
  description = "BASIC or STANDARD_HA, By default, BASIC is used."
}

variable "memory_size" {
  type        = number
  description = "Units is GB"
}

variable "redis_version" {
  type    = string
  default = "REDIS_6_X"
}

variable "network_id" {
  type        = string
  description = "The VPC network id of the redis instance."
}

variable "region" {
  type    = string
  default = "asia-northeast1"
}

variable "zone" {
  type    = string
  default = "asia-northeast1-a"
}

variable "labels" {
  type    = map(string)
  default = {}
}
