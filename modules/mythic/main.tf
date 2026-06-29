locals {
  script_vars = {
    mythic_version        = var.mythic_version
    mythic_admin_user     = var.mythic_admin_user
    mythic_admin_password = var.mythic_admin_password
    mythic_agent          = var.mythic_agent
    mythic_c2_profile     = var.mythic_c2_profile
  }
}

##################################################################
# SSH 
##################################################################

# We should probably do this differently.

data "azurerm_resource_group" "ssh" {
  name = var.resource_group
}

resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = data.azurerm_resource_group.ssh.location
  parent_id = data.azurerm_resource_group.ssh.id
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

##################################################################
# Linux Virtual Machine 
##################################################################

data "azurerm_resource_group" "this" {
  name = var.resource_group
}

# Create virtual network
resource "azurerm_virtual_network" "mythic_vm" {
  name                = "${var.project}myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

# Create subnet
resource "azurerm_subnet" "segmentation" {
  name                 = "${var.project}mySubnet"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.mythic_vm.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "mythic_server" {
  name                = "${var.project}myPublicIP"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Static"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "ssh_rule" {
  name                = "${var.project}myNetworkSecurityGroup"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

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
  name                = "${var.project}myNIC"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "${var.project}my_nic_configuration"
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
    resource_group = data.azurerm_resource_group.this.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mythic_base" {
  name                     = "diag${random_id.storage_account_id.hex}"
  location                 = data.azurerm_resource_group.this.location
  resource_group_name      = data.azurerm_resource_group.this.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "mythic_platform" {
  name                  = "${var.project}-mythic"
  location              = data.azurerm_resource_group.this.location
  resource_group_name   = data.azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.mythic_connection.id]
  size                  = "Standard_D2als_v6"
  user_data             = base64encode(templatefile("${path.module}/templates/install-mythic.sh.tftpl", local.script_vars))

  tags = {
    project = var.project
  }

  os_disk {
    name                 = "${var.project}myOsDisk"
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
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mythic_base.primary_blob_endpoint
  }
}

#Create CDN Front Door Profile Endpoint

resource "azurerm_cdn_frontdoor_profile" "mythic_profile" {
  name                = "CDNFrontdoorProfile"
  resource_group_name = data.azurerm_resource_group.this.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_origin_group" "backend_pool" {
  name                     = "CDNFrontdoorOriginGroup"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.mythic_profile.id

  load_balancing {}
}

resource "azurerm_cdn_frontdoor_origin" "backend_routing" {
  name                          = "CDNFrontdoorOrigin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backend_pool.id
  enabled                       = true

  certificate_name_check_enabled = false

  host_name          = azurerm_public_ip.mythic_server.ip_address
  http_port          = 80
  https_port         = 443
  origin_host_header = azurerm_public_ip.mythic_server.ip_address
  priority           = 1
  weight             = 1
}

resource "azurerm_cdn_frontdoor_endpoint" "mythic_endpoint" {
  name                     = "CDNFrontdoorEndpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.mythic_profile.id
}