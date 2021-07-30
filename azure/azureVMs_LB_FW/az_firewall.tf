# Create AzureFirewallSubnet
resource "azurerm_subnet" "fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = module.vnet.vnet_name
  address_prefixes     = ["10.0.0.0/26"]
}

# Create public IP for AzureFirewall
resource "azurerm_public_ip" "azure_fw_pip" {
  name                = "azure_fw-pip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Azure Firewall
resource "azurerm_firewall" "azure_fw" {
  name                = "azure_fw"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.fw_subnet.id
    public_ip_address_id = azurerm_public_ip.azure_fw_pip.id
  }
  
  depends_on = [module.vnet.vnet_subnets, azurerm_linux_virtual_machine.linux]

}

# Create default routes for accessing the Internet through the firewall
resource "azurerm_route_table" "route_table" {
  name                          = "route_table"
  location                      = azurerm_resource_group.resource_group.location
  resource_group_name           = azurerm_resource_group.resource_group.name
  disable_bgp_route_propagation = false

  # Outbound to internet
  route {
    name                   = "outbound-to-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.azure_fw.ip_configuration[0].private_ip_address
  }
}

# Associate the route table with subnets
resource "azurerm_subnet_route_table_association" "subnet_route_table_association" {
  count          = var.subnets_per_vnet
  route_table_id = azurerm_route_table.route_table.id
  subnet_id      = element(local.subnet_id.*, count.index)
}

# Create network rules
resource "azurerm_firewall_network_rule_collection" "allow_network_rules" {
  name                = "allow_network_rules"
  azure_firewall_name = azurerm_firewall.azure_fw.name
  resource_group_name = azurerm_resource_group.resource_group.name
  priority            = 200
  action              = "Allow"
  
  count               = var.subnets_per_vnet

  rule {
    name = "Allow-DNS"

    source_addresses = [
      element(local.subnet_prefix.*, count.index)
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "1.1.1.1",
      "1.0.0.1",
    ]

    protocols = [
      "TCP",
      "UDP",
    ]
  }
  
  /*
  # Allow HTTP/HTTPS to enable for example s/w downloads from vm - REMOVE WHEN DONE TESTING
  rule {
    name = "Allow-HTTP"

    source_addresses = [
      element(local.subnet_prefix.*, count.index)
    ]

    destination_ports = [
      "80",
      "443",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "TCP",
    ]
  }
  */
  
}

# Create application rules
resource "azurerm_firewall_application_rule_collection" "outbound-allow_application_rules" {
  name                = "outbound_allow_application_rules"
  azure_firewall_name = azurerm_firewall.azure_fw.name
  resource_group_name = azurerm_resource_group.resource_group.name
  priority            = 200
  action              = "Allow"
  
  count               = var.subnets_per_vnet

  # Allow google (http)
  rule {
    name = "Allow-Google-HTTP"

    source_addresses = [
      element(local.subnet_prefix.*, count.index)
    ]

    target_fqdns = [
      "*.google.com",
    ]

    protocol {
      port = "80"
      type = "Http"
    }
  }


  # Allow google (https)
  rule {
    name = "Allow-Google-HTTPS"

    source_addresses = [
      element(local.subnet_prefix.*, count.index)
    ]

    target_fqdns = [
      "*.google.com",
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }

}

# Create NAT rules
resource "azurerm_firewall_nat_rule_collection" "nat_rules" {
  name                = "nat_rules"
  azure_firewall_name = azurerm_firewall.azure_fw.name
  resource_group_name = azurerm_resource_group.resource_group.name
  priority            = 200
  action              = "Dnat"

  rule {
    name = "ssh-nat"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "22",
    ]

    destination_addresses = [
      azurerm_public_ip.azure_fw_pip.ip_address
    ]

    translated_port = 22

    translated_address = azurerm_lb.load_balancer.frontend_ip_configuration[0].private_ip_address

    protocols = [
      "TCP",
    ]
  }

  rule {
    name = "http-nat"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "80",
    ]

    destination_addresses = [
      azurerm_public_ip.azure_fw_pip.ip_address
    ]

    translated_port = 80

    translated_address = azurerm_lb.load_balancer.frontend_ip_configuration[0].private_ip_address

    protocols = [
      "TCP",
    ]
  }

}
# Access information on public IP address of firewall
data "azurerm_public_ip" "azure_fw_pip" {
  name                = azurerm_public_ip.azure_fw_pip.name
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Output to console the public IP address of the firewall
output "firewall_public_ip_address" {
  value = data.azurerm_public_ip.azure_fw_pip.ip_address
}

# Output to console the private IP address of the firewall
output "firewall_private_ip_address" {
  value = azurerm_firewall.azure_fw.ip_configuration[0].private_ip_address
}
