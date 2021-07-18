# Create subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.gateway.name
  virtual_network_name = azurerm_virtual_network.gateway.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "nginx_pip" {
  name                = "${var.prefix}-nginx-pip"
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "nginx_nic" {
  name                = "${var.prefix}-nginx-nic"
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name

  ip_configuration {
    name                          = "gatewayNicConfig"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nginx_pip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nginx_nic" {
  network_interface_id      = azurerm_network_interface.nginx_nic.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# Bootstrap Template File for installing nginx
data "template_file" "nginx-vm-cloud-init" {
  template = file("nginx_install.sh")
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "nginx" {
  name                = "${var.prefix}-nginx"
  resource_group_name = azurerm_resource_group.gateway.name
  location            = azurerm_resource_group.gateway.location
  size                = "Standard_B1ls"
  admin_username      = "<USERNAME>"                            # <----------------- EDIT ------------------
  computer_name       = "Linux-gateway"
  custom_data         = base64encode(data.template_file.nginx-vm-cloud-init.rendered)
  
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nginx_nic.id,
  ]
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  admin_ssh_key {
    username   = "<USERNAME>"                                    # <----------------- EDIT ------------------
    public_key = file("<PUBLIC KEY PATH>")                       # <----------------- EDIT ------------------
  }
  
}

# Access information on existing public IP address of the VM
data "azurerm_public_ip" "nginx_pip" {
  name                = azurerm_public_ip.nginx_pip.name
  resource_group_name = azurerm_linux_virtual_machine.nginx.resource_group_name
}

# Output to console the actual public IP address of the VM
output "nginx_public_ip_address" {
  value = data.azurerm_public_ip.nginx_pip.ip_address
}
