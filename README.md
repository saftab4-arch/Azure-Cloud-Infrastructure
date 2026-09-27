# Azure Cloud Infrastructure

Hands-on Microsoft Azure infrastructure projects built with Terraform.

This repository focuses on learning Infrastructure as Code through practical Azure deployments. This project focuses specifically on **Terraform reusable modules, module inputs and outputs, `for_each`, and communication between network and compute modules**.

---

# Lab 05 — Reusable Azure Infrastructure with Terraform Modules

## Overview

This lab demonstrates how Terraform child modules can be used to separate Azure infrastructure into reusable components.

Instead of defining networking and compute resources directly inside the root module, two child modules were created:

- **Network module** — creates the VNet, subnets, NSGs, NSG rules, and associations.
- **Compute module** — creates a private NIC and Linux virtual machine.

The compute module is reused twice to create two separate virtual machines without duplicating the NIC or VM resource code.

The root module acts as the orchestrator by supplying inputs to the child modules and passing network module outputs into the compute modules.

---

## Architecture

```text
                         Root Module
                             |
              +--------------+--------------+
              |                             |
              v                             v
        Network Module                Compute Module
              |                       (reused twice)
              |                        /          \
              v                       v            v
      Azure Virtual Network        Web VM       App VM
          10.50.0.0/16               |            |
              |                       |            |
       +------+-------+              NIC          NIC
       |              |               |            |
       v              v               |            |
   Web Subnet      App Subnet         |            |
       |              |               |            |
      NSG            NSG              |            |
       |              |               |            |
       +--------------+---------------+------------+
```

Both virtual machines use **private IP addresses only**.

No public IP addresses are created in this lab.

---

## Infrastructure Created

The Terraform configuration creates:

- 1 Azure Virtual Network
- 2 Azure subnets
  - Web subnet
  - Application subnet
- 2 Network Security Groups
- NSG security rules
- NSG-to-subnet associations
- 2 Azure network interfaces
- 2 Linux virtual machines
  - Web VM
  - Application VM
- Dynamically allocated private IP addresses

The Resource Group already exists and is supplied to the modules as an input.

---

# Project Structure

```text
.
├── main.tf
├── variables.tf
├── terraform.tfvars
├── locals.tf
├── outputs.tf
├── version.tf
├── .gitignore
│
└── modules/
    ├── network/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── compute/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

`terraform.tfvars` is used locally and excluded from Git through `.gitignore`.

---

# Root Module

The root module acts as the **orchestrator**.

It does not contain the actual VNet, subnet, NSG, NIC, or VM resource implementations.

Instead, it calls the child modules and supplies the values they require.

The root module calls:

```text
module "network"
module "web_vm"
module "app_vm"
```

The network module is called once.

The same compute module is called twice:

```text
                    modules/compute
                           |
                    NIC + Linux VM
                           |
                   +-------+-------+
                   |               |
                   v               v
             module.web_vm    module.app_vm
                   |               |
                   v               v
                Web VM           App VM
```

This demonstrates the main purpose of reusable Terraform modules.

---

# Network Module

The network child module contains the Terraform resource definitions responsible for Azure networking.

It creates:

- Virtual Network
- Subnets
- Network Security Groups
- NSG security rules
- NSG-to-subnet associations

The root module passes the network configuration into the child module.

Conceptually:

```text
Root configuration
       |
       v
module "network"
       |
       v
modules/network/
       |
       +-- VNet
       +-- Subnets
       +-- NSGs
       +-- NSG Rules
       +-- Associations
```

---

## Creating Multiple Subnets with `for_each`

The subnet configuration is represented as a map.

Conceptually:

```hcl
subnets = {
  web = {
    address_prefix = "10.50.1.0/24"
    tier           = "web"
  }

  app = {
    address_prefix = "10.50.2.0/24"
    tier           = "app"
  }
}
```

The network module uses:

```hcl
for_each = var.subnets
```

Terraform therefore creates separate resource instances for each map key:

```text
azurerm_subnet.subnets["web"]
azurerm_subnet.subnets["app"]
```

The same approach is used where appropriate for the related networking resources.

This avoids writing separate nearly identical resource blocks for the web and application networks.

---

# Network Module Outputs

The compute module needs to know which subnet its NIC should use.

However, the subnet resources exist inside the network child module.

The network module therefore exposes the subnet IDs through an output:

```hcl
output "subnet_ids" {
  value = {
    for key, subnet in azurerm_subnet.subnets :
    key => subnet.id
  }
}
```

The `for` expression transforms the subnet resources into a map conceptually similar to:

```text
{
  web = "<web-subnet-resource-id>"
  app = "<app-subnet-resource-id>"
}
```

The root module can then access:

```hcl
module.network.subnet_ids["web"]
```

and:

```hcl
module.network.subnet_ids["app"]
```

---

# Compute Module

The compute child module contains the reusable Terraform configuration for:

- Azure Network Interface
- Private IP configuration
- Linux Virtual Machine
- SSH public-key configuration
- OS disk
- Ubuntu Linux image

The module receives values such as:

```text
location
resource_group_name
subnet_id
vm_name
vm_size
admin_username
ssh_public_key
```

The compute module does not need to know whether it is creating a web server or application server.

It simply creates a NIC and VM using the values supplied by the root module.

---

# Compute Module Reuse

The compute module is written only once:

```text
modules/compute/
├── main.tf
├── variables.tf
└── outputs.tf
```

The root module reuses it to create the web VM:

```hcl
module "web_vm" {
  source = "./modules/compute"

  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.subnet_ids["web"]

  vm_name        = "${local.name_prefix}-web-vm"
  vm_size        = var.vm_size
  admin_username = var.admin_username
  ssh_public_key = var.ssh_public_key
}
```

The exact same child module is then reused for the application VM:

```hcl
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
```

The resource implementation does not change.

Only the inputs change.

```text
SAME COMPUTE MODULE
        |
   +----+----+
   |         |
   v         v
Web VM     App VM
   |         |
   v         v
Web NIC    App NIC
   |         |
   v         v
Web Subnet App Subnet
```

---

# Module-to-Module Communication

One of the main concepts practiced in this lab is passing information between modules.

For the web VM:

```hcl
subnet_id = module.network.subnet_ids["web"]
```

The complete flow is:

```text
NETWORK CHILD MODULE
        |
        | creates
        v
    Web Subnet
        |
        | Azure resource ID
        v
Network child output
   subnet_ids["web"]
        |
        v
      ROOT
        |
        | passes value into
        v
COMPUTE CHILD MODULE
        |
        v
  var.subnet_id
        |
        v
      NIC
        |
        v
   Web Subnet
```

The application VM follows the same pattern using:

```hcl
module.network.subnet_ids["app"]
```

This keeps the network and compute modules separate while allowing the root module to connect them together.

---

# Private NIC Configuration

Each VM receives its own Azure Network Interface.

The NIC is connected to the subnet supplied by the root module:

```hcl
ip_configuration {
  name                          = "internal"
  subnet_id                     = var.subnet_id
  private_ip_address_allocation = "Dynamic"
}
```

`Dynamic` means Azure automatically selects an available private IP address from the selected subnet.

No public IP is attached to either NIC.

---

# VM-to-NIC Relationship

The Linux VM attaches to the NIC created inside the same compute module:

```hcl
network_interface_ids = [
  azurerm_network_interface.nic.id
]
```

The resulting relationship is:

```text
Linux VM
   |
   v
Azure NIC
   |
   v
Private IP
   |
   v
Subnet
   |
   v
Virtual Network
```

---

# Compute Module Outputs

The compute child module exposes useful information about the resources it creates.

VM ID:

```hcl
output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}
```

Private IP:

```hcl
output "private_ip_address" {
  value = azurerm_network_interface.nic.private_ip_address
}
```

Because the compute module is instantiated twice, root can independently access:

```hcl
module.web_vm.vm_id
module.web_vm.private_ip_address
```

and:

```hcl
module.app_vm.vm_id
module.app_vm.private_ip_address
```

---

# Root Outputs

The root module exposes the final infrastructure information.

Examples include:

```text
VNet ID
Subnet IDs
Web VM ID
Web VM private IP
App VM ID
App VM private IP
```

The important distinction is:

```text
Child module output
        |
        | makes internal resource information
        | available to the parent/root
        v
Root module
        |
        | optionally exposes final information
        v
terraform output
```

Child outputs are also used internally to connect modules together.

---

# Variables and `terraform.tfvars`

Root variables define the values that the root module expects.

Actual environment-specific values are supplied through:

```text
terraform.tfvars
```

The general flow is:

```text
terraform.tfvars
       |
       v
Root variables
       |
       v
Root module
       |
       v
Child module inputs
       |
       v
Azure resources
```

Child modules have their own `variables.tf`.

A child variable is separate from a root variable even when both use the same name.

For example:

```text
ROOT var.vm_size
       |
       | vm_size = var.vm_size
       v
CHILD var.vm_size
```

The root module is responsible for connecting the two.

---

# Locals

Local values are used for calculated values such as consistent resource naming.

For example, a common naming prefix can be calculated once and reused when generating resource names.

Conceptually:

```text
environment
    |
    v
local.name_prefix
    |
    +-- web VM name
    +-- app VM name
    +-- VNet name
```

This avoids repeating naming logic throughout the configuration.

---

# Variable Validation

Variable validation is used to restrict accepted environment values.

The environment is limited to:

```text
dev
test
prod
```

This prevents an unsupported environment value from being accepted accidentally.

---

# Remote Terraform State

Terraform state for this project is stored remotely using the AzureRM backend.

The backend uses:

```text
Azure Storage Account
        |
        v
Blob Container
        |
        v
Terraform State Blob
```

Remote state keeps Terraform state outside the Git repository and provides centralized state storage for the deployment.

---

# Terraform Workflow

Format the configuration:

```bash
terraform fmt -recursive
```

Initialize Terraform and the configured backend:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Review the proposed infrastructure changes:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

View the root outputs:

```bash
terraform output
```

Destroy the lab infrastructure when testing is complete:

```bash
terraform destroy
```

---

# Git Safety

Terraform runtime and environment-specific files are excluded using `.gitignore`.

Examples include:

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json
```

The Terraform dependency lock file can remain committed:

```text
.terraform.lock.hcl
```

Private SSH keys must never be committed to the repository.

---

# Terraform Concepts Practiced

This lab provided hands-on practice with:

- Root modules
- Child modules
- Reusable modules
- Module inputs
- Module outputs
- Module reuse
- Module-to-module data flow
- Variables
- `terraform.tfvars`
- Locals
- Variable validation
- Maps
- Objects
- `for_each`
- `for` expressions
- Resource references
- Resource attributes
- Azure-generated resource IDs
- Dynamic private IP allocation
- AzureRM remote backend
- Terraform formatting
- Terraform initialization
- Terraform validation
- Terraform planning
- Terraform deployment
- Terraform destroy

---

# Key Takeaway

The main lesson from this lab is that Terraform modules allow infrastructure logic to be written once and reused with different inputs.

Instead of duplicating resources:

```text
Write Web NIC
Write Web VM

Write App NIC
Write App VM
```

one reusable compute module can be called multiple times:

```text
              Reusable Compute Module
                     NIC + VM
                        |
                  +-----+-----+
                  |           |
                  v           v
                Web VM      App VM
```

The root module controls **what should be deployed**, while the child modules contain **how those infrastructure components are created**.

This separation makes Terraform configurations easier to reuse, organize, and expand as infrastructure becomes more complex.
