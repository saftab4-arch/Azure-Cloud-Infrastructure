locals {
  name_prefix = "${var.environment}-lab5"


  common_tags = {
    Enviroment = var.environment
    ManagedBy  = "Terraform"
    Project    = "Terraform-Lab5"

  }

}


