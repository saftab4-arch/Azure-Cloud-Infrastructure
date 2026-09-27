variable "resource_group_name" {
  type        = string
  description = "Name of the Lab 5 infrastructure resource group"
}

variable "location" {
  type        = string
  description = "Azure region for Lab 5 resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
}

variable "subnets" {
  description = "Subnet configuration"

  type = map(object({
    address_prefix = string
    tier           = string

  }))

}


variable "vm_size" {
  type        = string
  description = "Azure VM size"
}

variable "admin_username" {
  type        = string
  description = "Administrator username for the Linux VM"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for the Linux VM"
}

