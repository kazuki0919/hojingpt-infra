data "azurerm_ssh_public_key" "main" {
  name                = var.ssh_key
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_interface" "main" {
  name                = "nic-${var.name}-batch-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "default"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                       = "vm-${var.name}-batch-001"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  network_interface_ids      = [azurerm_network_interface.main.id]
  size                       = "Standard_B1s"
  encryption_at_host_enabled = true

  patch_assessment_mode = "AutomaticByPlatform"
  patch_mode            = "AutomaticByPlatform"
  reboot_setting        = "IfRequired"

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

  computer_name  = "vm-${var.name}-batch-001"
  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.main.public_key
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    role = "data-collect"
  })
}

resource "azurerm_virtual_machine_extension" "main_sshlogin" {
  name                       = "AADSSHLogin"
  virtual_machine_id         = azurerm_linux_virtual_machine.main.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_virtual_machine_extension" "main_monitor_agent" {
  name                       = "AzureMonitorAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.main.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}
