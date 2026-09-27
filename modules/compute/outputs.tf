output "vm_id" {
  description = "ID of the Linux virtual machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "private_ip_address" {
  description = "Private IP address assigned to the VM NIC"
  value       = azurerm_network_interface.nic.private_ip_address
}
