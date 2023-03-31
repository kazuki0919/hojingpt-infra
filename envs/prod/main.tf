terraform {
  backend "gcs" {
    bucket = "givery-hojingpt-tfstate-prod"
    prefix = "hojingpt"
  }
}

locals {
  project = "hojingpt-prod"
  env     = "prod"
  region  = "asia-northeast1"
}

provider "google" {
  project = local.project
  region  = local.region
}

module "project_services" {
  source = "../../modules/project_services"
}

module "network" {
  source      = "../../modules/network"
  project     = local.project
  region      = local.region
  name        = "hojingpt"
  name_suffix = "-${local.env}"
}

module "spanner" {
  source           = "../../modules/database/spanner"
  project          = local.project
  name             = "hojingpt-instance-${local.env}"
  db               = "hojingpt"
  config           = "regional-asia-northeast1"
  processing_units = 100

  labels = {
    env     = local.env
    service = "hojingpt"
    source  = "spanner"
  }

  depends_on = [module.project_services]
}

# TODO
# module "spanner_autoscaler" {
#   source       = "../../modules/database/spanner/autoscaler"
#   project      = local.project
#   region       = local.region
#   name         = "hojingpt"
#   name_suffix  = "-${local.env}"
#   spanner_name = module.spanner.name
#   depends_on   = [module.project_services]

#   monitoring_enabled = true
# }

module "redis" {
  source      = "../../modules/cache/redis"
  name        = "hojingpt-${local.env}"
  tier        = "STANDARD_HA"
  memory_size = 5
  network_id  = module.network.default.id

  depends_on = [module.project_services]
}
