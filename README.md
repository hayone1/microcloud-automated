# Microcloud Automated

<!-- [![GitHub Issues](https://img.shields.io/github/issues/acch/ansible-boilerplate.svg)](https://github.com/acch/ansible-boilerplate/issues) [![GitHub Stars](https://img.shields.io/github/stars/acch/ansible-boilerplate.svg?label=github%20%E2%98%85)](https://github.com/acch/ansible-boilerplate/) [![License](https://img.shields.io/github/license/acch/ansible-boilerplate.svg)](LICENSE) -->

[Micro Cloud](https://canonical-microcloud.readthedocs-hosted.com/en/latest/) allows you to deploy your own fully functional private cloud in minutes.

This project is generally intended for experimentation/evaluation and can be improved/customized to fit your unique needs to become production ready.


## 1. Getting-Started

Download (clone) or fork this repository.
The major places of interest for customization will be in the [group_vars](group_vars/) folder.

### 1.1 Pre-requisites
- [yq](https://github.com/mikefarah/yq/#install)
- [jq](https://jqlang.github.io/jq/download/)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [taskfile](https://taskfile.dev/installation/)

To-Do: link to infra folder
### 1.2 Infra
To setup microcloud you will need to have compute and network resources. This could be from a cloud provider or your private servers.

- Inside the [group_vars](group_vars/) folder, edit the `all.yml` file, and specify the environments you're interested in setting-up under the `groups:` field. Arbitrary values are allowed
 eg.
```
groups:
  - dev
  - uat
```

- Also in the group_vars folder, duplicate the `dev.yml` and `dev.env`(used to hold required environment variables and secrets) files to match the number of items/environments you have put in the `groups:` field and rename each file to match the items in the groups.
eg.
```
dev.yml
uat.yml
dev.env
uat.env
```
- In each group/environment specific file, specify the `ansible_user:`, `ansible_ssh_public_key_file:`, `ansible_ssh_private_key_file:` and `infra_provider` you are interested in deploying compute to. You can deploy arbitrary values or one of the supported cloud providers of this project.

eg.
``` yaml
ansible_user: root
infra_providers:
  self_hosted:
  digital_ocean:
```
> Currently supported cloud providers are: `digital_ocean`.

- If using a supported cloud provider, you can specify the `size`, `quantity:` and `region:` under the cloud provider's field.
eg.
``` yaml
infra_providers:
  digital_ocean:
    # custom, nano, micro, small, medium, large, xlarge, 2xlarge
    size: nano
    # number of servers to be provisioned
    quantity: 3
    # see valid regions here https://slugs.do-api.dev/
    region: "nyc3"
  aws:
    # custom, nano, micro, small, medium, large, xlarge, 2xlarge
    size: custom
    # valid only if size is set to custom
    custom_size: t2.micro
    # number of servers to be provisioned
    quantity: 3
    # see valid regions here https://slugs.do-api.dev/
    region: "nyc3"
```

- If you have already setup your compute by yourself or used a provivder that is not supported, then you'll need to specify the `hosts` alone.

  This is essentially ansible hosts config so you can input any valid ansible hosts value. See [here](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html).
``` yaml
infra_providers:
  self_hosted:
    hosts:  # only host field will be used
      www[01:50].example.com:
      10.1.1.0:
      10.1.1.1:
      host.example.com:
        http_port: 80
        maxRequestsPerChild: 808
    quantity: 3 # has no effect
```
> Important: This project is currently only guarranteed to work on **ubuntu** >= 22 OS and not otherwise.

- You can also have multiple infra_providers.
eg.
```yaml
infra_providers:
  self_hosted:
    hosts:
      64.18.0.0:
      64.18.0.1:
  digital_ocean:
    size: nano
    quantity: 3
    region: "nyc3"
```

- Take a detour and head over to the [infra-template](infra-template/) folder and locate the sub folder(s) of the infra_provider(s) you chose and go through their respective README(s).

- Once details of your cloud provider(s) has been provided. Run the below command to set up your compute.
```
task infra-deploy
```
> You can pass in valid terraform apply args by specifying them after "--" and separated by space.
eg. `task infra-deploy -- -auto-approve` 

> **Very Important**: No matter the approach you take to create your compute resources,
you must **ensure they are visible to each other over a local or private network!**

## 2 Deployment<a id='2'></a>

## 3 Maintainers<a id='3'></a>

## 4 Community<a id='4'></a>

- Contributing
    - Contributions are very welcome. See [contributing guide](CONTRIBUTING.md).
- To-Do
    - Add automated compute provisioning support for:
      - aws
      - azure
      - gcp
      - vagrant
    - Add steps to actually provision microcloud cluster.

## Maintainers
- Boluwatife @hayone1
- Deborah @Debby77

## Copyright and license

This project is released under the [GNU GPLv3](LICENSE)
