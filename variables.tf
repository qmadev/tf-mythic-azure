variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "mythic"
}

variable "resource_group_location" {
  type        = string
  default     = "West Europe"
  description = "Location of the resource group."
}

variable "vm-username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
}

variable "mythic_version" {
  type        = string
  description = "The Mythic C2 version to install"
  default     = "v3.4.0.5"
}

variable "mythic_admin_user" {
  type        = string
  description = "The username of the Mythic admin account"
  default     = "mythic_admin"
}

variable "mythic_agent" {
  type        = string
  description = "The Github URL of the Mythic C2 agent to install"
  default     = "https://github.com/MythicAgents/Apollo"
}

variable "mythic_c2_profile" {
  type        = string
  description = "The Github URL of the Mythic C2 profile to install"
  default     = "https://github.com/MythicC2Profiles/http"
}

variable "cdn_frontdoor_endpoints" {
  type        = number
  description = "The number of CDN endpoints to use"
  default     = 0
}

variable "key_vault_object_id" {
  type        = string
  description = "The object id of the user/group that should get access to the Key Vault"
}
