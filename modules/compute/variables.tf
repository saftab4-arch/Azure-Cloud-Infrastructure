variable "location" {
  type        = string
  description = "Azure region for compute resources"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group containing compute resources"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the VM network interface"
}

variable "vm_name" {
  type        = string
  description = "Name of the Linux virtual machine"
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
