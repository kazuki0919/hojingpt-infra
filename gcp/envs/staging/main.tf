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

module "network" {
  source      = "../../modules/network"
  project     = local.project
  region      = local.region
  name        = "hojingpt"
  name_suffix = "-${local.env}"
}

# module "storage" {
#   source      = "../../modules/storage"
#   name        = "hojingpt"
#   name_suffix = "-${local.env}"
#   region      = local.region
# }

# module "redis" {
#   source      = "../../modules/cache/redis"
#   name        = "hojingpt-${local.env}"
#   tier        = "BASIC"
#   memory_size = 2
#   network_id  = module.network.default_network.id
# }

# module "mysql" {
#   source             = "../../modules/database/mysql"
#   name               = "hojingpt"
#   name_suffix        = "-${local.env}"
#   region             = local.region
#   database_version   = "MYSQL_8_0_26"
#   tier               = "db-custom-2-8192"
#   availability_type  = "ZONAL"
#   allocated_ip_range = module.network.default_global_address.name
#   private_network    = module.network.default_network.id
# }

# module "app" {
#   source   = "../../modules/apps/cloudrun"
#   project  = local.project
#   location = local.region
#   name     = "hojingpt"
# }

# module "bastion" {
#   source        = "../../modules/bastion"
#   project       = local.project
#   region        = local.region
#   name          = "hojingpt-bastion-${local.env}"
#   network_id    = module.network.default_network.id
#   subnetwork_id = module.network.default_subnetwork.name

#   labels = {
#     env     = local.env
#     service = "hojingpt"
#     source  = "bastion"
#   }
# }

# data "google_monitoring_notification_channel" "slack" {
#   for_each = {
#     emergency = "EmergencyCall for ${local.env}"
#     events    = "SystemEvents for ${local.env}"
#   }
#   display_name = each.value
#   type         = "slack"
# }

# module "monitoring" {
#   source      = "../../modules/monitoring"
#   project     = local.project
#   name        = "hojingpt"
#   name_suffix = "-${local.env}"

#   emergency_channel = data.google_monitoring_notification_channel.slack["emergency"].name
#   events_channel    = data.google_monitoring_notification_channel.slack["events"].name

#   logs = {
#     cloudrun = [
#       { service_name = "hojingpt" }
#     ]
#   }

#   cloudrun = {
#     max_size        = module.app.max_size
#     max_concurrency = module.app.max_concurrency
#   }
# }

# module "logging" {
#   source      = "../../modules/logging"
#   project     = local.project
#   location    = local.region
#   name        = "hojingpt"
#   name_suffix = "-${local.env}"
# }

module "gce_shared" {
  source      = "../../modules/apps/gce/shared"
  name        = "hojingpt"
  name_suffix = "-${local.env}"
  network_id  = module.network.default_network.id
}

module "llama_index_demo" {
  source                = "../../modules/apps/gce"
  name                  = "givery-llama-index-demo"
  service_account_email = module.gce_shared.service_account_email
  subnetwork_id         = module.network.default_subnetwork.name
}
