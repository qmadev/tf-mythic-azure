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

data "azurerm_resource_group" "mythic" {
  name = var.resource_group
}

resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = data.azurerm_resource_group.mythic.location
  parent_id = data.azurerm_resource_group.mythic.id
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

data "azurerm_resource_group" "tf_mythic" {
  name = var.resource_group
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${var.project}myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.tf_mythic.location
  resource_group_name = data.azurerm_resource_group.tf_mythic.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "${var.project}mySubnet"
  resource_group_name  = data.azurerm_resource_group.tf_mythic.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${var.project}myPublicIP"
  location            = data.azurerm_resource_group.tf_mythic.location
  resource_group_name = data.azurerm_resource_group.tf_mythic.name
  allocation_method   = "Static"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${var.project}myNetworkSecurityGroup"
  location            = data.azurerm_resource_group.tf_mythic.location
  resource_group_name = data.azurerm_resource_group.tf_mythic.name

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
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${var.project}myNIC"
  location            = data.azurerm_resource_group.tf_mythic.location
  resource_group_name = data.azurerm_resource_group.tf_mythic.name

  ip_configuration {
    name                          = "${var.project}my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = data.azurerm_resource_group.tf_mythic.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = data.azurerm_resource_group.tf_mythic.location
  resource_group_name      = data.azurerm_resource_group.tf_mythic.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "${var.project}-mythic"
  location              = data.azurerm_resource_group.tf_mythic.location
  resource_group_name   = data.azurerm_resource_group.tf_mythic.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
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
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}
