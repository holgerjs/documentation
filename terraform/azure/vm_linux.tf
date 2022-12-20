# Create network interface
resource "azurerm_network_interface" "nic_ubn_01" {
  name                = "nic_ubn-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_ubn-01-configuration"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm_ubn_01" {
  name                  = "vm-ubn-01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_ubn_01.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "disk-os-ubn-01"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm-ubn-01"
  admin_username                  = "ubn-azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "ubn-azureuser"
    public_key = tls_private_key.ubn_ssh.public_key_openssh
  }
}