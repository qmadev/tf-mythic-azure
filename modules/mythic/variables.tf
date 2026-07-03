variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to use"
}

variable "resource_group_location" {
  type        = string
  description = "The location of the resource group to use"
}

variable "azure_key_vault_id" {
  type        = string
  description = "The id of the key vault to use"
}

variable "project" {
  type        = string
  description = "The name of the project"
}

variable "vm-username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
}

variable "mythic_version" {
  type        = string
  description = "The Mythic C2 version to install"
}

variable "mythic_admin_user" {
  type        = string
  description = "The username of the Mythic admin account"
}

variable "mythic_agent" {
  type        = string
  description = "The Github URL of the Mythic C2 agent to install"
}

variable "mythic_c2_profile" {
  type        = string
  description = "The Github URL of the Mythic C2 profile to install"
}

variable "cdn_frontdoor_endpoints" {
  type        = number
  description = "The number of CDN endpoints to use"
}
