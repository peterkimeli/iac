terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stfinsenseterraform"
    container_name       = "tfstate"
    key                  = "ms-account-service/dev.tfstate"
  }
}
