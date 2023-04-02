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
  source             = "../../modules/cache/redis"
  name               = "hojingpt-${local.env}"
  tier               = "STANDARD_HA"
  memory_size        = 5
  replica_count      = 1
  read_replicas_mode = "READ_REPLICAS_ENABLED"
  network_id         = module.network.default_network.id

  depends_on = [module.project_services]
}

# TODO
# module "app" {
#   source          = "../../modules/apps/cloudrun"
#   project         = local.project
#   name            = "hojingpt"
#   location        = local.region
#   connector_name  = module.network.default_vpc_access_connector.name
#   container_image = "gcr.io/hojingpt-${local.env}/hojingpt"
# }

module "bastion" {
  source        = "../../modules/bastion"
  project       = local.project
  region        = local.region
  name          = "hojingpt-bastion-${local.env}"
  network_id    = module.network.default_network.id
  subnetwork_id = module.network.default_subnetwork.name
 
  labels = {
    env     = local.env
    service = "hojingpt"
    source  = "bastion"
  }
}
