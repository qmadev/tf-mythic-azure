locals {
  projects = {
    newtest = {
      vm-username           = "adminuser"
      mythic_admin_user     = "asdf"
      mythic_admin_password = "moreasdf"
      mythic_c2_profile     = "https://github.com/MythicC2Profiles/httpx"
    }
    newproject = {}
  }
}

module "bootstrap" {
  source = "./modules/bootstrap"

  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
}

module "mythic" {
  source   = "./modules/mythic"
  for_each = local.projects

  resource_group        = var.resource_group_name
  project               = each.key
  vm-username           = lookup(each.value, "vm-username", var.vm-username)
  mythic_version        = lookup(each.value, "mythic_version", var.mythic_version)
  mythic_admin_user     = lookup(each.value, "mythic_admin_user", var.mythic_admin_user)
  mythic_admin_password = lookup(each.value, "mythic_admin_password", var.mythic_admin_password)
  mythic_agent          = lookup(each.value, "mythic_agent", var.mythic_agent)
  mythic_c2_profile     = lookup(each.value, "mythic_c2_profile", var.mythic_c2_profile)
}
