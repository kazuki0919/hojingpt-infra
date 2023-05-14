variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

resource "azurerm_user_assigned_identity" "main" {
  name                = "id-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

output "user_assigned_identity" {
  value = azurerm_user_assigned_identity.main
}
