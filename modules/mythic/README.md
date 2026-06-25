
# Mythic module

Module that creates the resources to host a Mythic C2 service. It uses a VM of type `Standard_D2als_v6` which should meet the minimum requirement of 2 CPUs and 4GB RAM.

## Input

|variable    | description|
|------------|------------|
|resource_group_name | Name of the resource group to create|
|location| Azure location to create the resource group in| 
|resource_group|The resource group to use|
|project|The name of the project|
|vm-username| The username for the local account that will be created on the new VM.|
|mythic_version| The Mythic C2 version to install|
|mythic_admin_user| The username of the Mythic admin account|
|mythic_admin_password| The password of the Mythic admin account|
|mythic_agent| The Github URL of the Mythic C2 agent to install|
|mythic_c2_profile| The Github URL of the Mythic C2 profile to install|

## Output

|variable    | description|
|------------|------------|
|public_ip_address| The public IP address of the server|
