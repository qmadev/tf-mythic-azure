# Terraforming Mythic

This project allows operators to set up multiple Mythic C2 servers in Azure. Optionally, Azure CDN redirectors can be created as well.

## Usage

Inside the [main.tf](main.tf) file is a `projects` map. You can add projects to that map. Every project will get their own Mythic C2 instance. Different variables can be added to configure Mythic, like the credentials and the C2 agent to install. For example:

```terraform
locals {
  projects = {

    # Custom Mythic deployment.
    hackeverything = {
      vm-username             = "adminuser"
      mythic_version          = "v3.2.2"
      mythic_admin_user       = "asdf"
      mythic_admin_password   = "moreasdf"
      mythic_c2_profile       = "https://github.com/MythicC2Profiles/httpx"
      mythic_agent            = "https://github.com/MythicAgents/Xenon"
      cdn_frontdoor_endpoints = 2
    }
    
    # Default Mythic deployment.
    hacksomething = {}
  }
}
```

## OPSEC

Currently, it's just the basic Mythic C2 installation as [documented](https://docs.mythic-c2.net/version-2.3/installation). The Mythic portal listens on localhost. You could use ssh local port forwarding to access it, e.g.

```bash
ssh -L 127.0.0.1:7443:127.0.0.1:7443 <VM-USERNAME>@<IP>
```

## Secrets

There are two secrets that you will need:
1. The SSH key for the VM
2. The password for the Mythic Web Console

You need to know the name of the Azure Key Vault, which can be found in the Azure Portal, and the name of your project. Use the `az` command to get the secrets.

```bash
# SSH Key
az keyvault secret show --vault-name <KEY VAULT NAME> --name <PROJECT-sshkey> | jq .value -r

# Web Console Password
az keyvault secret show --vault-name <KEY VAULT NAME> --name <PROJECT-mythic-admin>

```

## Notes

This project was primarily used for learning more about Terraform, Mythic and Azure.
