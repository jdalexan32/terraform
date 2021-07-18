output "vnet_subnets" {
  description = "The ids of subnets created inside the vnet"
  value       = module.vnet.vnet_subnets
}

output "linux_public_ip_address" {
  value = [azurerm_public_ip.vm_pip.*.name,
    data.azurerm_public_ip.vm_pip.*.ip_address,
  ]
}
