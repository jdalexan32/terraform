# Create subnet
resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.gateway.name
  virtual_network_name = azurerm_virtual_network.gateway.name
  address_prefixes     = ["10.1.255.0/27"]
}

# Create public IP
resource "azurerm_public_ip" "vnetgateway_pip" {
  name                = "gateway-vNetGateway-pip"
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name
  allocation_method   = "Dynamic"
}

# Create virtual network gateway
resource "azurerm_virtual_network_gateway" "vNetGateway" {
  name                = "${var.prefix}-vNetGateway"
  location            = azurerm_resource_group.gateway.location
  resource_group_name = azurerm_resource_group.gateway.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vnetgateway_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.GatewaySubnet.id
  }
  
  vpn_client_configuration {
    address_space        = ["176.17.200.0/24"]
    vpn_client_protocols = ["OpenVPN"]

    root_certificate {
      name = "P2SRootCert"

      # Enter below the public certificate            # <----------------- EDIT ------------------
      public_cert_data = <<EOF
<HERE>
EOF
    }
  }
}
