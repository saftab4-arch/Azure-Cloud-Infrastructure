module "network" {

	source   = "./modules/network"

	location            = var.location
	resource_group_name = var.resource_group_name
	vnet_name           = "${local.name_prefix}-vnet"
	vnet_address_space  = var.vnet_address_space
        subnets             = var.subnets

}


module "web_vm" {
	source = "./modules/compute"

	
	location            = var.location
	resource_group_name = var.resource_group_name
        subnet_id           = module.network.subnet_ids["web"]

        vm_name             = "${local.name_prefix}-web-vm"
        vm_size             =  var.vm_size
	admin_username      =  var.admin_username
        ssh_public_key      =  var.ssh_public_key

}


module "app_vm" {
  source = "./modules/compute"

  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.subnet_ids["app"]

  vm_name        = "${local.name_prefix}-app-vm"
  vm_size        = var.vm_size
  admin_username = var.admin_username
  ssh_public_key = var.ssh_public_key
}
