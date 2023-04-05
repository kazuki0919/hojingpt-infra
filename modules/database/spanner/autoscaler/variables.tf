variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-northeast1"
}

variable "name" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "spanner_name" {
  type = string
}

variable "min_size" {
  type        = number
  description = "Minimum processing units that the spanner instance can be scaled in to."
}

variable "max_size" {
  type        = number
  description = "Maximum processing units that the spanner instance can be scaled out to."
}
