resource "azuread_application" "mythic_cicd" {
  display_name = "tf-mythic-github-cicd"
}

# resource "azuread_service_principal" "mythic_cicd" {
#   client_id = azuread_application.mythic_cicd.client_id
# }
#
# data "azurerm_subscription" "current" {}
#
# resource "azurerm_role_assignment" "mythic_cicd" {
#   scope                = data.azurerm_subscription.current.id
#   role_definition_name = "Contributor"
#   principal_id         = azuread_service_principal.mythic_cicd.object_id
# }
#
# resource "azuread_application_federated_identity_credential" "tf_mythic_github_main" {
#   application_id = azuread_application.mythic_cicd.id
#   display_name   = "tf-mythic-github-main"
#
#   audiences = ["api://AzureADTokenExchange"]
#   issuer    = "https://token.actions.githubusercontent.com"
#
#   subject = "repo:qmadev/tf-mythic-azure:ref:refs/heads/main"
# }
#
#
# resource "azuread_application_federated_identity_credential" "tf_mythic_github_pr" {
#   application_id = azuread_application.mythic_cicd.id
#   display_name   = "tf-mythic-github-pr"
#
#   audiences = ["api://AzureADTokenExchange"]
#   issuer    = "https://token.actions.githubusercontent.com"
#
#   subject = "repo:qmadev/tf-mythic-azure:pull_request"
# }
#
resource "azurerm_resource_group" "tf_mythic" {
  name     = "mythic"
  location = "West Europe"
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

