variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_monitor_action_group" "watch" {
  name                = "mag-${var.name}-watch"
  resource_group_name = var.resource_group_name
  short_name          = "SystemAlert"

  logic_app_receiver {
    callback_url            = "https://prod-13.japaneast.logic.azure.com:443/workflows/a8970e4a4a7246cdae123cdd03bfa385/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=g74W9WGsJ90PfWxb4Zo3i55aMpuj9WlaUGtLBH4zMVU"
    name                    = "hojingpt-watch"
    resource_id             = "/subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-stage/providers/Microsoft.Logic/workflows/la-hojingpt-stage-watch"
    use_common_alert_schema = true
  }
}
