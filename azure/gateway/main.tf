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
resource "azurerm_resource_group" "gateway" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# Create virtual network (vnet)
resource "azurerm_virtual_network" "gateway" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "gateway" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name

    security_rule {
        name                       = "Allow-SSH"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Allow-HTTP"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "10.1.255.0/27" # allow only from GatewaySubnet
        destination_address_prefix = "*"
    }

}
