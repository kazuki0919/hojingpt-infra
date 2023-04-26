variable "name" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnetwork_id" {
  type = string
}

variable "source_image" {
  type    = string
  default = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "disk_size" {
  type    = number
  default = 10
}

variable "labels" {
  type    = map(any)
  default = {}
}
