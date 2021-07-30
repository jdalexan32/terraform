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

# Create Network Security Group(s) and rules for VMs in the subnet(s)
resource "azurerm_network_security_group" "subnet_nsg" {
  count               = var.subnets_per_vnet
  name                = "${var.project_name}-subnet${count.index}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name

    # Rule for SHH'ing into VMs
    security_rule {
        name                       = "Allow-SSH"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "0.0.0.0/0"
        destination_address_prefix = "*"
    }

    # HTTP for access to nginx web page
    security_rule {
        name                       = "Allow-HTTP"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "0.0.0.0/0"
        destination_address_prefix = "*"
    }

    # Demo rule to show a higher priority Deny rule that is not impacted becuase a lower priority Allow rule exists
    security_rule {
        name                       = "Deny-SHH-from-Internet->NO-IMPACT"
        priority                   = 1020
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
    }

}

# Create Network Security Group(s) and rules for nic(s)
resource "azurerm_network_security_group" "nic_nsg" {
  name                = "${var.project_name}-linux0-nic-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name

    # Ping rule
    security_rule {
        name                       = "Allow-Ping"
        priority                   = 1015
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "ICMP"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    # Rule for SHH'ing into VMs
    security_rule {
        name                       = "Allow-SSH"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "0.0.0.0/0"
        destination_address_prefix = "*"
    }

}

# map subnets to Network Security Group ID(s)
locals {
  count         = var.subnets_per_vnet
  subnet_id     = module.vnet.vnet_subnets.*
  subnet_prefix = slice(var.subnet_prefixes, 0, var.subnets_per_vnet)
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  count                     = var.subnets_per_vnet
  subnet_id                 = element(local.subnet_id.*, count.index)
  network_security_group_id = element(azurerm_network_security_group.subnet_nsg.*.id, count.index)
}

# Create public IP(s)
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

# Associate NIC Security Group to "linux0" VM
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.vm_nic.0.id
  network_security_group_id = azurerm_network_security_group.nic_nsg.id
}

# Bootstrap Template File for configuring linux
data "template_file" "linux-vm-cloud-init" {
  template = file("linux_config.sh")
}

# Create virtual machine(s)
resource "azurerm_linux_virtual_machine" "linux" {
  count               = var.vm_instances_per_subnet * length(module.vnet.vnet_subnets)
  name                = "${var.project_name}-linux${count.index}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  size                = "Standard_B1ls"
  admin_username      = var.user_name
  computer_name       = "linux${count.index}"
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
