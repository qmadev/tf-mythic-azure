# Terraforming Mythic

This project allows operators to set up multiple Mythic C2 servers in Azure. Optionally, Azure CDN redirectors can be created as well.

## Usage

Inside the [main.tf](main.tf) file is a `projects` map. You can add projects to that map. Every project will get their own Mythic C2 instance. Different variables can be added to configure Mythic, like the credentials and the C2 agent to install. For example:

```terraform
locals {
  projects = {

    # Custom Mythic deployment.
    hackeveryone = {
      vm-username           = "adminuser"
      mythic_version        = "v3.2.2"
      mythic_admin_user     = "asdf"
      mythic_admin_password = "moreasdf"
      mythic_c2_profile     = "https://github.com/MythicC2Profiles/httpx"
      mythic_agent          = "https://github.com/MythicAgents/Xenon"
    }
    
    # Default Mythic deployment.
    basicmythic = {}
  }
}
```

## OPSEC

Currently, it's just the basic Mythic C2 installation as [documented](https://docs.mythic-c2.net/version-2.3/installation). The Mythic portal listens on localhost. You could use ssh local port forwarding to access it, e.g.

```bash
ssh -L 127.0.0.1:7443:127.0.0.1:7443 <USERNAME>@<IP>
```
