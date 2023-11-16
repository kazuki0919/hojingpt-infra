resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_bastion.cidrs
}

# see: https://learn.microsoft.com/ja-jp/azure/bastion/bastion-nsg#apply
resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-${var.name}-bastion-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Inbound rules
  security_rule {
    direction                  = "Inbound"
    priority                   = 120
    name                       = "AllowHttpsInbound"
    destination_port_range     = "443"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    access                     = "Allow"
  }

  security_rule {
    direction                  = "Inbound"
    priority                   = 130
    name                       = "AllowGatewayManagerInbound"
    destination_port_range     = "443"
    protocol                   = "Tcp"
    source_address_prefix      = "GatewayManager"
    source_port_range          = "*"
    destination_address_prefix = "*"
    access                     = "Allow"
  }

  security_rule {
    direction                  = "Inbound"
    priority                   = 140
    name                       = "AllowAzureLoadBalancerInbound"
    destination_port_range     = "443"
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
    destination_address_prefix = "*"
    access                     = "Allow"
  }

  security_rule {
    direction                  = "Inbound"
    priority                   = 150
    name                       = "AllowBastionHostCommunication"
    destination_port_ranges    = ["8080", "5701"]
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Allow"
  }

  # Outbound rules
  security_rule {
    direction                  = "Outbound"
    priority                   = 100
    name                       = "AllowSshRdpOutbound"
    destination_port_ranges    = ["3389","22"]
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Allow"
  }

 security_rule {
    direction                  = "Outbound"
    priority                   = 110
    name                       = "AllowAzureCloudOutbound"
    destination_port_range     = "443"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "AzureCloud"
    access                     = "Allow"
  }

 security_rule {
    direction                  = "Outbound"
    priority                   = 120
    name                       = "AllowBastionCommunication"
    destination_port_ranges    = ["8080", "5701"]
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Allow"
  }

 security_rule {
    direction                  = "Outbound"
    priority                   = 130
    name                       = "AllowHttpOutbound"
    destination_port_range     = "80"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    access                     = "Allow"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}
