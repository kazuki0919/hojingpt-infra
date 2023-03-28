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
