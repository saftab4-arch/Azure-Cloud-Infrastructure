terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-lab5"
    storage_account_name = "syedtfstatelab5"
    container_name       = "tfstate"
    key                  = "lab5/terraform.tfstate"


  }

}


