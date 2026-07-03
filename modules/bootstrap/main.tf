##################################################################
# Resource Group and Storage
##################################################################

resource "azurerm_resource_group" "tf_mythic" {
  name     = var.resource_group_name
  location = var.location
}

resource "random_string" "resource_code" {
  length  = 5
  special = false
  upper   = false
  lower   = false
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "tfstate${random_string.resource_code.result}"
  resource_group_name             = azurerm_resource_group.tf_mythic.name
  location                        = azurerm_resource_group.tf_mythic.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_storage_encryption_scope" "tfstate" {
  name               = "tfstate"
  storage_account_id = azurerm_storage_account.tfstate.id
  source             = "Microsoft.Storage"
}
