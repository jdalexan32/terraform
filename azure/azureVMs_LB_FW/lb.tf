# Create lb subnet
resource "azurerm_subnet" "lb_subnet" {
  name                 = "${var.project_name}-lb-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = module.vnet.vnet_name
  address_prefixes     = ["10.0.10.0/24"]
}

# load balancer nsg
module "lb_security_group" {
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = var.location
  security_group_name   = "${var.project_name}-lb-nsg"
  source_address_prefix = ["0.0.0.0/0"]
  predefined_rules = [
    {
      name     = "SSH"
      priority = "1000"
    },
  ]

  custom_rules = [
    {
      name                   = "HTTP"
      priority               = 1010
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "tcp"
      source_port_range      = "*"
      destination_port_range = "80"
      source_address_prefix  = "0.0.0.0/0"
      description            = "Allow HTTP ingress"
    },
  ]
  
  depends_on = [azurerm_resource_group.resource_group]
}

# Front end Load Balancer
resource "azurerm_lb" "load_balancer" {
  name                = "${var.project_name}-load_balancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name

  frontend_ip_configuration {
    name                          = "${var.project_name}-load_balancer-frontend_ipconfig"
    subnet_id                     = azurerm_subnet.lb_subnet.id
    private_ip_address            = "10.0.10.4"
    private_ip_address_allocation = "Static"
  }
}
# Back end address pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "${var.project_name}-load_balancer-backend_address_pool"
  loadbalancer_id = azurerm_lb.load_balancer.id
}

# Associate back end address pool with VMs
resource "azurerm_network_interface_backend_address_pool_association" "backend_pool" {
  count                   = var.vm_instances_per_subnet * var.subnets_per_vnet
  network_interface_id    = element(azurerm_network_interface.vm_nic.*.id, count.index)
  ip_configuration_name   = "${var.project_name}-nicConfig${count.index % var.vm_instances_per_subnet}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# LB Probe - checks to see which VMs are healthy and available
resource "azurerm_lb_probe" "load_balancer_probe" {
  resource_group_name = azurerm_resource_group.resource_group.name
  loadbalancer_id     = azurerm_lb.load_balancer.id
  name                = "${var.project_name}-load_balancer-health_probe"
  port                = 80
}

# Load Balancer Rules
resource "azurerm_lb_rule" "load_balancer_http_rule" {
  resource_group_name            = azurerm_resource_group.resource_group.name
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "HTTPRule"
  protocol                       = "TCP"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.project_name}-load_balancer-frontend_ipconfig"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  probe_id                       = azurerm_lb_probe.load_balancer_probe.id
  
  depends_on = [azurerm_lb_probe.load_balancer_probe]
}

resource "azurerm_lb_rule" "load_balancer_https_rule" {
  resource_group_name            = azurerm_resource_group.resource_group.name
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "HTTPSRule"
  protocol                       = "TCP"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.project_name}-load_balancer-frontend_ipconfig"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  probe_id                       = azurerm_lb_probe.load_balancer_probe.id
  
  depends_on = [azurerm_lb_probe.load_balancer_probe]
}

resource "azurerm_lb_rule" "load_balancer_ssh_rule" {
  resource_group_name            = azurerm_resource_group.resource_group.name
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "SSHRule"
  protocol                       = "TCP"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.project_name}-load_balancer-frontend_ipconfig"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  probe_id                       = azurerm_lb_probe.load_balancer_probe.id
  
  depends_on = [azurerm_lb_probe.load_balancer_probe]
}
