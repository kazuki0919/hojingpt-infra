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

module "storage" {
  source      = "../../modules/storage"
  name        = "hojingpt"
  name_suffix = "-${local.env}"
  region      = local.region
}

# module "spanner" {
#   source           = "../../modules/database/spanner"
#   project          = local.project
#   name             = "hojingpt-instance-${local.env}"
#   db               = "hojingpt"
#   config           = "regional-asia-northeast1"
#   processing_units = 100

#   labels = {
#     env     = local.env
#     service = "hojingpt"
#     source  = "spanner"
#   }
# }

# module "spanner_autoscaler" {
#   source             = "../../modules/database/spanner/autoscaler"
#   project            = local.project
#   region             = local.region
#   name               = "hojingpt"
#   name_suffix        = "-${local.env}"
#   spanner_name       = module.spanner.name
#   min_size           = 100
#   max_size           = 2000
#   monitoring_enabled = true
#   function_bucket    = module.storage.function_source_bucket.name
# }

# module "spanner_scheduled_backups" {
#   source          = "../../modules/database/spanner/scheduled-backups"
#   project         = local.project
#   region          = local.region
#   name            = "hojingpt"
#   name_suffix     = "-${local.env}"
#   function_bucket = module.storage.function_source_bucket.name
#   instance_id     = module.spanner.name
#   database_id     = module.spanner.db
# }

module "redis" {
  source      = "../../modules/cache/redis"
  name        = "hojingpt-${local.env}"
  tier        = "BASIC"
  memory_size = 2
  network_id  = module.network.default_network.id
}

module "mysql" {
  source             = "../../modules/database/mysql"
  name               = "hojingpt"
  name_suffix        = "-${local.env}"
  region             = local.region
  database_version   = "MYSQL_8_0_26"
  tier               = "db-custom-2-8192"
  availability_type  = "ZONAL"
  allocated_ip_range = module.network.default_global_address.name
  private_network    = module.network.default_network.id
}

module "app" {
  source   = "../../modules/apps/cloudrun"
  project  = local.project
  location = local.region
  name     = "hojingpt"
}

# module "load_balancer" {
#   source      = "../../modules/loadbalancer"
#   project     = local.project
#   region      = local.region
#   name        = "hojingpt"
#   name_suffix = "-${local.env}"

#   app_service_name = module.app.service_name

#   domains = [
#     "staging.hojingpt.com",
#   ]
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

data "google_monitoring_notification_channel" "slack" {
  for_each = {
    emergency = "EmergencyCall for ${local.env}"
    events    = "SystemEvents for ${local.env}"
  }
  display_name = each.value
  type         = "slack"
}

module "monitoring" {
  source      = "../../modules/monitoring"
  project     = local.project
  name        = "hojingpt"
  name_suffix = "-${local.env}"

  emergency_channel = data.google_monitoring_notification_channel.slack["emergency"].name
  events_channel    = data.google_monitoring_notification_channel.slack["events"].name

  logs = {
    cloudrun = [
      { service_name = "hojingpt" }
    ]
  }

  # spanner = {
  #   max_size = module.spanner_autoscaler.max_size
  # }

  cloudrun = {
    max_size        = module.app.max_size
    max_concurrency = module.app.max_concurrency
  }
}

# TODO: The Function is not yet complete.
# module "notification" {
#   source          = "../../modules/notification"
#   name            = "hojingpt"
#   name_suffix     = "-${local.env}"
#   project         = local.project
#   location        = local.region
#   function_bucket = module.storage.function_source_bucket.name
# }

module "logging" {
  source      = "../../modules/logging"
  project     = local.project
  location    = local.region
  name        = "hojingpt"
  name_suffix = "-${local.env}"
}

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
