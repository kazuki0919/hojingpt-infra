terraform {
  backend "gcs" {
    bucket = "givery-hojingpt-tfstate-staging"
    prefix = "hojingpt"
  }
}

locals {
  project = "hojingpt-staging"
  env     = "staging"
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

# module "redis" {
#   source = "../../modules/cache/redis"
#   name   = "hojingpt-${local.env}"

#   depends_on = [module.project_services]
# }