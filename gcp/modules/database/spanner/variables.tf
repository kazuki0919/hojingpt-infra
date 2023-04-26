variable "name" {
  type = string
}

variable "db" {
  type = string
}

variable "project" {
  type = string
}

variable "config" {
  type        = string
  description = "Cloud Spanner Instance config - Regional / multi-region. For allowed configurations, check: https://cloud.google.com/spanner/docs/instances#available-configurations-regional"
}

variable "num_nodes" {
  type        = number
  default     = null
  description = "The number of nodes allocated to this instance. Comment num_nodes block if want to go with processing units, instead of node counts."
}

variable "processing_units" {
  type        = number
  default     = null
  description = "The number of processing units allocated to this instance. Specify quantities up to 1000 processing units in multiples of 100 processing units (100, 200, 300 and so on) & specify greater quantities in multiples of 1000 processing units (1000, 2000, 3000 and so on). Uncomment if want to go with processing units, instead of node counts."
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "ddl_queries" {
  type    = list(string)
  default = []
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "spanner_instance_timeout" {
  type        = string
  default     = "10m"
  description = "How long a Google Spanner Instance creation operation is allowed to take before being considered a failure."
}

variable "spanner_db_timeout" {
  type        = string
  default     = "6m"
  description = "How long a Google Spanner Instance DB creation operation is allowed to take before being considered a failure."
}
