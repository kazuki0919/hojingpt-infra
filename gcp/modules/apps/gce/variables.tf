variable "name" {
  type = string
}

variable "zone" {
  type    = string
  default = "asia-northeast1-b"
}

variable "machine_type" {
  type    = string
  default = "e2-small"
}

variable "labels" {
  type    = map(any)
  default = {}
}

variable "tags" {
  type    = list(string)
  default = [
    "http-server",
    "https-server",
    "ssh"
  ]
}

variable "service_account_email" {
  type = string
}

variable "subnetwork_id" {
  type = string
}

variable "nic_type" {
  type    = string
  default = null # GVNIC or VIRTIO_NET
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "disk_type" {
  type    = string
  default = "pd-balanced" # or "pd-ssd"
}

variable "image" {
  type    = string
  default = "https://www.googleapis.com/compute/v1/projects/debian-cloud/global/images/debian-11-bullseye-v20230411"
}
