locals {
  script_vars = {
    mythic_version        = var.mythic_version
    mythic_admin_user     = var.mythic_admin_user
    mythic_admin_password = random_password.mythic.result
    mythic_agent          = var.mythic_agent
    mythic_c2_profile     = var.mythic_c2_profile
  }
}

##################################################################
# SSH key and password
##################################################################

resource "random_password" "mythic" {
  length  = 20
  special = false
}

resource "tls_private_key" "ed25519" {
  algorithm = "ED25519"
}

# Store SSH private key and Mythic password in Azure Key Vault
resource "azurerm_key_vault_secret" "ssh_key" {
  name         = "${var.project}-sshkey"
  value        = tls_private_key.ed25519.private_key_openssh
  key_vault_id = var.azure_key_vault_id
}

resource "azurerm_key_vault_secret" "mythic_password" {
  name         = "${var.project}-mythic-admin"
  value        = random_password.mythic.result
  key_vault_id = var.azure_key_vault_id
}

##################################################################
# Linux Virtual Machine 
##################################################################

resource "azurerm_virtual_network" "mythic_vm" {
  name                = var.project
  address_space       = ["10.0.0.0/16"]
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

# Create subnet
resource "azurerm_subnet" "segmentation" {
  name                 = var.project
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.mythic_vm.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "mythic_server" {
  name                = var.project
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "ssh_rule" {
  name                = var.project
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "mythic_connection" {
  name                = var.project
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = var.project
    subnet_id                     = azurerm_subnet.segmentation.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mythic_server.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nic_connection" {
  network_interface_id      = azurerm_network_interface.mythic_connection.id
  network_security_group_id = azurerm_network_security_group.ssh_rule.id
}

# Generate random text for a unique storage account name
resource "random_id" "storage_account_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = var.resource_group_name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mythic_base" {
  name                     = "diag${random_id.storage_account_id.hex}"
  location                 = var.resource_group_location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "mythic_platform" {
  name                  = "${var.project}-mythic"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.mythic_connection.id]
  size                  = "Standard_D2als_v6"
  user_data             = base64encode(templatefile("${path.module}/templates/install-mythic.sh.tftpl", local.script_vars))

  tags = {
    project = var.project
  }

  os_disk {
    name                 = "${var.project}OSDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  computer_name  = "${var.project}-mythic"
  admin_username = var.vm-username

  admin_ssh_key {
    username   = var.vm-username
    public_key = tls_private_key.ed25519.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mythic_base.primary_blob_endpoint
  }
}

##################################################################
# Azure FrontDoor CDN
##################################################################

resource "azurerm_cdn_frontdoor_profile" "mythic_profile" {
  count = var.cdn_frontdoor_endpoints > 1 ? 1 : 0

  name                = "MythicRedirector"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_origin_group" "backend_pool" {
  count = var.cdn_frontdoor_endpoints > 1 ? 1 : 0

  name                     = "MythicRedirector"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.mythic_profile[*].id

  load_balancing {}
}

resource "azurerm_cdn_frontdoor_origin" "backend_routing" {
  count = var.cdn_frontdoor_endpoints > 1 ? 1 : 0

  name                           = "MythicRedirector"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.backend_pool[*].id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = azurerm_public_ip.mythic_server.ip_address
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_public_ip.mythic_server.ip_address
  priority                       = 1
  weight                         = 1
}

resource "azurerm_cdn_frontdoor_endpoint" "mythic_endpoint" {
  count                    = var.cdn_frontdoor_endpoints
  name                     = "MythicServer"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.mythic_profile[*].id
}
