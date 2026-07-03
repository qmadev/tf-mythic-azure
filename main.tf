locals {
  projects = {
    # Custom Mythic deployment.
    # hackeverything = {
    #   vm-username             = "adminuser"
    #   mythic_version          = "v3.2.2"
    #   mythic_admin_user       = "asdf"
    #   mythic_c2_profile       = "https://github.com/MythicC2Profiles/httpx"
    #   mythic_agent            = "https://github.com/MythicAgents/Xenon"
    #   cdn_frontdoor_endpoints = 2
    # }

    # Default Mythic deployment.
    # hacksomething = {}
  }
}

module "bootstrap" {
  source = "./modules/bootstrap"

  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
}

data "azurerm_client_config" "current" {}

resource "random_string" "vault_name" {
  length  = 5
  special = false
  upper   = false
  lower   = false
}

resource "azurerm_key_vault" "mythic" {
  name                       = "mythic${random_string.vault_name.result}"
  location                   = module.bootstrap.resource_group.location
  resource_group_name        = module.bootstrap.resource_group.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  rbac_authorization_enabled = false

  access_policy {
    # Security group that can read the secrets from this Azure Key Vault
    object_id = var.key_vault_object_id
    tenant_id = data.azurerm_client_config.current.tenant_id

    key_permissions    = ["Get", "List", "Delete"]
    secret_permissions = ["Set", "Get", "List", "Delete", "Purge"]
  }
}


module "mythic" {
  source   = "./modules/mythic"
  for_each = local.projects

  resource_group_name     = module.bootstrap.resource_group.name
  resource_group_location = module.bootstrap.resource_group.location
  azure_key_vault_id      = azurerm_key_vault.mythic.id
  project                 = each.key
  vm-username             = lookup(each.value, "vm-username", var.vm-username)
  mythic_version          = lookup(each.value, "mythic_version", var.mythic_version)
  mythic_admin_user       = lookup(each.value, "mythic_admin_user", var.mythic_admin_user)
  mythic_agent            = lookup(each.value, "mythic_agent", var.mythic_agent)
  mythic_c2_profile       = lookup(each.value, "mythic_c2_profile", var.mythic_c2_profile)
  cdn_frontdoor_endpoints = lookup(each.value, "cdn_frontdoor_endpoints", var.cdn_frontdoor_endpoints)
}
