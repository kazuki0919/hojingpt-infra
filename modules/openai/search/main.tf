variable "name" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  default     = "standard"
  type        = string
  description = "The sku must be one of the following values: free, basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2."
}

variable "replica_count" {
  type        = number
  default     = 1
  description = "The replica_count must be between 1 and 12."
}

variable "partition_count" {
  type        = number
  description = "The partition_count must be one of the following values: 1, 2, 3, 4, 6, 12."
  default     = 1
}

variable "allow_ips" {
  type    = list(string)
  default = []
}

variable "private_endpoint" {
  type = object({
    subnet_id   = string
    location    = string
    dns_zone_id = string
  })
  default = null
}

variable "public_access_enabled" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_search_service" "main" {
  name                          = "srch-${var.name}-${var.name_suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  replica_count                 = var.replica_count
  partition_count               = var.partition_count
  allowed_ips                   = var.allow_ips
  public_network_access_enabled = var.public_access_enabled
  tags                          = var.tags
}

resource "azurerm_private_endpoint" "main" {
  count               = var.private_endpoint == null ? 0 : 1
  name                = "pep-${var.name}-srch-${var.name_suffix}"
  location            = var.private_endpoint.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id
  tags                = var.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "private-cogsearch-connection"
    private_connection_resource_id = azurerm_search_service.main.id
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_endpoint.dns_zone_id]
  }
}

output "id" {
  value = azurerm_search_service.main.id
}
