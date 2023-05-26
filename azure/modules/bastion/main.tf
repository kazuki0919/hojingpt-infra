variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ssh_key" {
  type = string
}

variable "allow_ips" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_public_ip" "main" {
  name                = "pip-${var.name}-bastion-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.name}-bastion-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = length(var.allow_ips) > 0 ? null : "*"
    source_address_prefixes    = var.allow_ips
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_network_interface" "main" {
  name                = "nic-${var.name}-bastion-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "default"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.main.id
}

data "azurerm_ssh_public_key" "main" {
  name                = var.ssh_key
  resource_group_name = var.resource_group_name
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = "vm-${var.name}-bastion-001"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = "Standard_B1s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "vm-${var.name}-bastion-001"
  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.main.public_key
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "sshlogin" {
  name                       = "AADSSHLogin"
  virtual_machine_id         = azurerm_linux_virtual_machine.main.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}
