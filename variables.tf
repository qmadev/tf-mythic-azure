variable "resource_group_location" {
  type        = string
  default     = "West Europe"
  description = "Location of the resource group."
}

# # variable "resource_group_name_prefix" {
#   type        = string
#   default     = "rg"
#   description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
# }

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
}

variable "mythic_version" {
  type        = string
  description = "The Mythic C2 version to install"
}

variable "mythic_admin_user" {
  type        = string
  description = "The username of the Mythic admin account"
}

variable "mythic_admin_password" {
  type        = string
  sensitive   = true
  description = "The password of the Mythic admin account"
}

variable "mythic_agent" {
  type        = string
  description = "The Github URL of the Mythic C2 agent to install"
}

variable "mythic_c2_profile" {
  type        = string
  description = "The Github URL of the Mythic C2 profile to install"
}
