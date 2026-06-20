terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.78.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.9.0"
    }
  }

  backend "azurerm" {
    resource_group_name = "mythic"
    storage_account_name = "tfstate97159"
    container_name = "tfstate"
    key = "terraform.tfstate"
  }

  required_version = "~> 1.15.0"
}
