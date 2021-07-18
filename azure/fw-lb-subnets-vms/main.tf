# Configure Azure Provider source and version being used
# https://registry.terraform.io/providers/hashicorp/azurerm/latest
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.56.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscriptionid
}

# Create resource group
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resourcegroup}-rg"
  location = var.location
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = [var.vnet_cidr_block]
  subnet_prefixes     = slice(var.subnet_prefixes, 0, var.subnets_per_vnet)
  subnet_names        = slice(var.subnet_names, 0, var.subnets_per_vnet)

  vnet_name           = "${var.resourcegroup}-vnet"
  
  depends_on = [azurerm_resource_group.resource_group]
}

# Create Network Security Group and rules for VMs in the subnets
resource "azurerm_network_security_group" "subnet_nsg" {
  name                = "${var.project_name}-subnets-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name

    # Rule for SHH'ing into VMs
    security_rule {
        name                       = "Allow-Ingress-SSH"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "10.0.10.0/24" # allow only from load balancer subnet 10.0.10.0/24
        destination_address_prefix = "*"
    }

    # HTTP for access to nginx web page
    security_rule {
        name                       = "Allow-Ingress-HTTP"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "10.0.10.0/24" # allow only from load balancer subnet 10.0.10.0/24
        destination_address_prefix = "*"
    }

    # HTTP outbound
    security_rule {
        name                       = "Allow-Egress-HTTP"
        priority                   = 1000
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "10.0.1.0/24"
        destination_address_prefix = "*"
    }

}

# map subnets to Network Security Group ID
locals {
  count         = var.subnets_per_vnet
  subnet_id     = module.vnet.vnet_subnets.*
  subnet_prefix = slice(var.subnet_prefixes, 0, var.subnets_per_vnet)
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  count                     = var.subnets_per_vnet
  subnet_id                 = element(local.subnet_id.*, count.index)
  network_security_group_id = azurerm_network_security_group.subnet_nsg.id
}

# Create public IP
resource "azurerm_public_ip" "vm_pip" {
  count               = var.vm_instances_per_subnet * length(module.vnet.vnet_subnets)
  name                = "${var.project_name}-linux${count.index}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Dynamic"
}

# Create network interfaces (NICs)
resource "azurerm_network_interface" "vm_nic" {
  count               = var.vm_instances_per_subnet * length(module.vnet.vnet_subnets)
  name                = "${var.project_name}-linux${count.index}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "${var.project_name}-nicConfig${count.index}"
    subnet_id                     = element(local.subnet_id.*, count.index)
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.vm_pip.*.id, count.index) # public IP for VMs is not required
  }
}

# Create Availability Set for VMs in each subnet
resource "azurerm_availability_set" "vm_availability_set" {
  name                = "${var.project_name}-vm_availability_set"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Bootstrap Template File for configuring linux
data "template_file" "linux-vm-cloud-init" {
  template = file("linux_config.sh")
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "linux" {
  count               = var.vm_instances_per_subnet * length(module.vnet.vnet_subnets)
  name                = "${var.project_name}-linux${count.index}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  availability_set_id = azurerm_availability_set.vm_availability_set.id
  size                = "Standard_B1ls"
  admin_username      = "<USERNAME>"                                                      # <----------------- EDIT ------------------
  computer_name       = "linux${count.index % var.vm_instances_per_subnet}"
  custom_data         = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  
  disable_password_authentication = true

  network_interface_ids = [
    element(azurerm_network_interface.vm_nic.*.id, count.index),
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
    username   = var.user_name
    public_key = file(var.public_key_path)
  }
  
}

# Access information on existing public IP address of the VMs
data "azurerm_public_ip" "vm_pip" {
  count               = var.vm_instances_per_subnet * length(module.vnet.vnet_subnets)
  name                = element(azurerm_public_ip.vm_pip.*.name, count.index)
  resource_group_name = azurerm_linux_virtual_machine.linux[count.index].resource_group_name
}
