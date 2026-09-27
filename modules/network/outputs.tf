output "vnet_id" {

  description = "ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id

}


output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"

  value = {
    for key, subnet in azurerm_subnet.subnets :
    key => subnet.id
  }
}
