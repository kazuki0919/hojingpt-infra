variable "endpoints" {
  type    = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "spanner.googleapis.com",
    "redis.googleapis.com",
  ]
}

resource "google_project_service" "default" {
  for_each           = toset(var.endpoints)
  service            = each.key
  disable_on_destroy = false
}
