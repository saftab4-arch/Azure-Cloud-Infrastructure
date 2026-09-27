variable "location" {
  type        = string
  description = "Azure region where network resources will be created"
}


variable "resource_group_name" {
  type        = string
  description = "Resource group containing the network resources"
}


variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the VNet"
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "subnets" {
  description = "Subnet configuration"

  type = map(object({
    address_prefix = string
    tier           = string
  }))
}
