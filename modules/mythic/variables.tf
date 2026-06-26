variable "resource_group" {
  type        = string
  description = "The resource group to use"
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

variable "cdn_frontdoor_endpoint" {
  type        = number 

  description = "The number of CDN endpoints to use"
}