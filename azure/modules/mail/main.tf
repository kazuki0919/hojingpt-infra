variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "data_location" {
  type    = string
  default = "Japan"
}

variable "diagnostics" {
  type = object({
    log_analytics_workspace_id = string
    storage_account_id         = string
  })
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_communication_service" "main" {
  name                = "acs-${var.name}-001"
  resource_group_name = var.resource_group_name
  data_location       = var.data_location
  tags                = var.tags
}

resource "azurerm_email_communication_service" "main" {
  name                = "acs-${var.name}-mail-001"
  resource_group_name = var.resource_group_name
  data_location       = var.data_location
  tags                = var.tags
  depends_on          = [azurerm_communication_service.main]
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                           = "acs-${var.name}-mail-001"
  target_resource_id             = azurerm_communication_service.main.id
  log_analytics_workspace_id     = var.diagnostics.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"
  storage_account_id             = var.diagnostics.storage_account_id

  enabled_log {
    category = "EmailSendMailOperational"
  }

  enabled_log {
    category = "EmailStatusUpdateOperational"
  }

  enabled_log {
    category = "EmailUserEngagementOperational"
  }

  metric {
    category = "Traffic"
    enabled  = false
  }

  lifecycle {
    # HACK: Suppresses diff generated by plan
    ignore_changes = [log_analytics_destination_type]
  }
}