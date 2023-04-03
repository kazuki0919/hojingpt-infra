variable "name" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "project" {
  type = string
}

variable "emergency_channel" {
  type = string
}

variable "events_channel" {
  type = string
}

variable "uptimes" {
  type = map(object({
    path     = string
    location = string
  }))
  default = {}
}

variable "labels" {
  type    = map(string)
  default = {}
}
