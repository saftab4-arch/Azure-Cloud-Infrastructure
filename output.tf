output "vnet_id" {
  description = "ID of the primary virtual network"
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value       = module.network.subnet_ids
}

output "web_vm_id" {
  description = "ID of the web virtual machine"
  value       = module.web_vm.vm_id
}

output "web_vm_private_ip" {
  description = "Private IP address of the web VM"
  value       = module.web_vm.private_ip_address
}

output "app_vm_id" {
  description = "ID of the app virtual machine"
  value       = module.app_vm.vm_id
}

output "app_vm_private_ip" {
  description = "Private IP address of the app VM"
  value       = module.app_vm.private_ip_address
}
