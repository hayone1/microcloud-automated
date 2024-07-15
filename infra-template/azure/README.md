# INFRA SETUP AZURE

**Welcome** to the azure infra setup.

## Setting-Up
> You can follow [this link](https://developer.hashicorp.com/terraform/tutorials/azure-get-started/azure-build)
to get a basic idea of how to setup this provider or if you encounter issues with this guide.

|Tested OS|
|---------|
|Ubuntu-24-04-lts|

- Ensure the `ansible_user:`, `ansible_ssh_public_key_file`, and `ansible_ssh_private_key_file:` have been set in your `<group-name>.yml` file.

- Create a subscription on [azure](https://portal.azure.com/).
- Install [azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) if you don't have it already.
    
    You can check by running `az version`. Also run `az upgrade` to get the latest version.

- Run `az login`, authenticate with azure, pick a subscription and take note of the Subscription ID.
If your terminal shows a url along with an `Operation not supported` message, simply copy or `ctrl` + Click the url
to open it in your browser.

- Your subscriptions will be listed and a a prompt will appear in the console to pick a the subscription
you'd like to use
eg:
```
No     Subscription name    Subscription ID                       Tenant
-----  -------------------  ------------------------------------  -----------------
[1] *  Azure for Students   xxxxxxxx-xxxxxxxx-xxxxxxxxx-xxxxxxxx  Default Directory
[2]    Dev Subscription     xxxxxxxx-xxxxxxxx-xxxxxxxxx-xxxxxxxx  Default Directory

The default is marked with an *; the default tenant is 'Default Directory' and subscription is 'Azure for Students' (e1e09e0b-6770-427c-9e73-6e649878f781).

Select a subscription and tenant (Type a number or Enter for no changes): 2
```
> Tip: Instead of installing the az cli locally, you can just use [azure cloud shell](https://shell.azure.com). You also can see more ways to login with the cli [here](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively).

- Create a service principal and assign the least role and scopes you think it should have.
Example for a blanket role/scope:
``` shell
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"
```
Example output
```
Creating 'Contributor' role assignment under scope '/subscriptions/35akss-subscription-id'
The output includes credentials that you must protect. Be sure that you do not include these credentials in your code or check the credentials into your source control. For more information, see https://aka.ms/azadsp-cli
{
  "appId": "xxxxxx-xxx-xxxx-xxxx-xxxxxxxxxx",
  "displayName": "azure-cli-2022-xxxx",
  "password": "xxxxxx~xxxxxx~xxxxx",
  "tenant": "xxxxx-xxxx-xxxxx-xxxx-xxxxx"
}
```

- You can choose to export the above values as environment variables with the following keys.
eg.
``` bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export ARM_TENANT_ID="<tenant>"
```
- If you don't want to export the variable all the time, you can create **at least one of** the following env files(priority is as listed) and put the environment variables there:
    - `<group-name>.env` file in the `group_vars` folder eg. dev.env(Highest priority).
    - `.env` file in the `group_vars` folder.
    - `.env` file at the root of the project (lowest priority).

The content will look like this:
```
ARM_CLIENT_ID=xxxxxxxx
ARM_CLIENT_SECRET=yyyyyyy
ARM_SUBSCRIPTION_ID=zzzzzzzzz
ARM_TENANT_ID=tttttttttttt
```
> Tip: .env files don't need double quotes.

- Create variables specific to this provider in your group vars file.
eg. in dev.yml
``` yaml
prefix: micro
#...
---
ansible_ssh_host_key_checking: false
ansible_user: microcloud
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_ssh_public_key_file: ~/.ssh/id_rsa.pub

# lookup_subnet: 10.0.1.1/24

prefix: micro
use_preseed: true
tag:
  System:       "microcloud"
  Creator:      "terraform"
  Environment:  "test"

infra_providers:
  azure:
    quantity: 3
    size: custom
    custom_sizes:
      - Standard_D2s_v3
      - Standard_D2s_v3
      - Standard_B2s
    security_rules:
      allowed_ports: [22, 80, 443, 8443]
      allowed_source_address_prefix: "0.0.0.0/0"
      allowed_destination_address_prefix: "0.0.0.0/0"
    # ingress_prefix
    image: # all mandatory
      publisher : "Canonical"
      offer     : "ubuntu-24_04-lts"
      sku       : "server"
      version   : "latest"
      # publisher : "Canonical"
      # offer     : "0001-com-ubuntu-server-jammy"
      # sku       : "22_04-lts"
      # version   : "latest"
    local_volume_sizes: [3]
    ceph_volume_sizes: [3]
    region: "westus"
    tag:
      Provider: "azure"

```
> Tip: Before configuring your sizing, you should consider checking your subscription resource quota limits
for your chosen region. eg. `az vm list-usage --location "West US 2" --output table`

- You can return back to the main [README](../../README.md) to complete the setup.
___

## More Info
- For a list of valid regions see [here](https://github.com/claranet/terraform-azurerm-regions/blob/master/regions.tf)
- For how to see valid VM images, see [here](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage)