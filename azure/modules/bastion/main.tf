data "azurerm_ssh_public_key" "main" {
  name                = var.ssh_key
  resource_group_name = var.resource_group_name
}

#
# Azure Bastion Service
#
resource "azurerm_public_ip" "main" {
  name                = "pip-${var.name}-bastion-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "main" {
  name                = "bastion-${var.name}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tunneling_enabled   = true

  ip_configuration {
    name                 = "default"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

#
# Backend Virtual Machine for Bastion
#
resource "azurerm_network_interface" "main" {
  name                = "nic-${var.name}-bastion-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "default"
    subnet_id                     = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
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
