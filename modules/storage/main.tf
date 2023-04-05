variable "name" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "region" {
  type = string
}

resource "google_storage_bucket" "function_source_bucket" {
  name                        = "${var.name}-function-source${var.name_suffix}"
  storage_class               = "REGIONAL"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}
