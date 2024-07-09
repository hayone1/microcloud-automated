
# Microcloud Automated
Automated provisioning of microcloud on private/public clouds at scale.

<!-- [![GitHub Issues](https://img.shields.io/github/issues/acch/ansible-boilerplate.svg)](https://github.com/acch/ansible-boilerplate/issues) [![GitHub Stars](https://img.shields.io/github/stars/acch/ansible-boilerplate.svg?label=github%20%E2%98%85)](https://github.com/acch/ansible-boilerplate/) [![License](https://img.shields.io/github/license/acch/ansible-boilerplate.svg)](LICENSE) -->

Terraform          |  Microcloud | Ansible
:-------------------------:|:-------------------------:|:-------------------------:
![alt text](./docs/photos/icon-Terraform-x128.png) |  ![alt text](./docs/photos/icon-microcloud-orange.png) | ![alt text](./docs/photos/icon-ansible-red-x128.png)


## Introduction

[MicroCloud](https://canonical-microcloud.readthedocs-hosted.com/en/latest/) claims to be micro because it allow you to provision your own fully functional private cloud in minutes in an opinionated way.

Installation is done using snap commands ans would greatly benefit from automated provisioning at scale. Hence **Microcloud Automated**.🤷‍♂️

> This project is generally intended for experimentation/evaluation and can be improved/customized to fit your unique needs to become production ready.

This project has 2 sections that can be independently deployed and managed. They are
1. Deploying network connected compute to various cloud providers in an opinionated yet flexible way.
2. Deploying microcloud on said or custom compute.

## TOC
<!-- TOC -->

- [Microcloud Automated](#microcloud-automated)
    - [Introduction](#introduction)
    - [TOC](#toc)
    - [Getting-Started](#getting-started)
        - [Pre-requisites](#pre-requisites)
        - [Infra](#infra)
            - [New Infra](#new-infra)
            - [Existing Infra](#existing-infra)
    - [Deployment](#deployment)
    - [Extra Configuration](#extra-configuration)
        - [Preseed](#preseed)
    - [To-Do](#to-do)
    - [Community](#community)
    - [Maintainers](#maintainers)
    - [Copyright and license](#copyright-and-license)

<!-- /TOC -->

## Getting-Started

Download (clone) or fork this repository.
The major places of interest for customization will be in the [group_vars](group_vars/) folder.

### Pre-requisites
- [yq 4.x](https://github.com/mikefarah/yq/#install)
- [jq](https://jqlang.github.io/jq/download/)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [taskfile](https://taskfile.dev/installation/)
- [faketime](https://manpages.ubuntu.com/manpages/trusty/man1/faketime.1.html) (Optional, but useful when using IBM Cloud)
  - Ensure your system time is correct and `date -u` gives the correct utc time!

### Infra
To setup microcloud you will need to have compute and network resources. This could be from a cloud provider or your private servers.

 - In the group_vars folder, duplicate the `dev.yml.example` and `dev.env.example` and remove `.example` from each file's name.
eg.
``` shell
dev.yml
uat.yml
# used to hold required environment variables and secrets
dev.env
uat.env
```
- In each group/environment specific file, specify the `ansible_user:`, `ansible_ssh_public_key_file:`, `ansible_ssh_private_key_file:`.

eg.
``` yaml
# dev.yml
ansible_ssh_host_key_checking: false
ansible_user: microcloud
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_ssh_public_key_file: ~/.ssh/id_rsa.pub
```

- **Take a detour to the [infra-template](infra-template/) folder and go through the respective README(s) of the infra_provider(s) you chose.**

#### New Infra
If you're provisioning your infra via this project, you can specify the `infra_providers:` you are interested in deploying compute to.
For `infra_providers:` You can use arbitrary values or one of the supported cloud providers of this project.

> Currently supported cloud providers are: `azure`.

- There are a couple of options available to you to specify.

eg.
``` yaml
#... truncated for brevity
ansible_ssh_public_key_file: ~/.ssh/id_rsa.pub
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
    custom_sizes: ["t2.micro"]
    # number of servers to be provisioned
    quantity: 3
    # see valid regions here https://slugs.do-api.dev/
    region: "nyc3"
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
    local_volume_sizes: [3]
    ceph_volume_sizes: [3]
    region: "westus"
    tag:
      Provider: "azure"
```
- There are also additional fields that can be specific for each cloud provider.
- If you specify `size: custom` in a provider, you must declear the  `custom_sizes:` list.
It's best to either make the `custom_sizes:` list have only one item or items equal to
`quantity:`.
> If your `custom_sizes:` list length is less than the `quantity:` value, then the remaining
servers will be assigned the size of the last entry in your `custom_sizes:` list.
This gives room for some interesting customizations on the size options you may want to configure.

| Supported Providers | status |
|---------------------|--------|
| custom              | ✅ |
| azure               | ✅ |
| digital_ocean       | 🟡 |
| oracle_cloud        | 🟡 |
| aliyun              | 🟡 |
| ibm_cloud           | ❌ |
| aws                 | ❌ |

#### Existing Infra
- If you have already setup your compute outside this project, then you can specify the `hosts:` field instead of the `infra_providers:` field.

  This is essentially ansible hosts config so you can put any valid ansible hosts value. See [official examples](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html).
- You'll need to make sure that your compute resources have:
  * layer 2 or layer 3 network connectivity to each other.
  * you have ssh and root access to said compute.
  * If you don't have your ssh keys added to the target nodes, then you'll need to
  specify your user details using the below keys to your env file:

``` env
# .env or <group>.env
TF_VAR_ANSIBLE_BECOME_PASS=sudo_user
TF_VAR_ANSIBLE_SSH_PASS=sudo_user_password
```

eg.
``` yaml
# sit.yml
#...
# For values that may be common to all hosts, you can specify them on this level eg.
common_config: 'Hello World'
infra_providers:
  # can be any name but try avoiding the exact names of the
  # supported cloud providers
  self_hosted:
    hosts:  # only host field will be used if specified
       # [mandatory]
      192.168.0.144: # public IP or private address that's reacheable from the master node execution environment.
        # [mandatory]
        hostname: homelabnode1
        # [mandatory]
        index_key: 0
        # [mandatory]
        ipv4_address: 192.168.0.144 # public IP or private address that's reacheable from the master node execution environment.
        # [mandatory]
        ipv4_address_iface: eno0
        # [mandatory]
        ipv4_address_private: 192.168.0.144
        # [mandatory]
        ipv4_address_private_iface: eno0
        # [mandatory]
        local_volume_path: /dev/mmcblk0
        # [mandatory]
        #This is The interface whose subnet will be used in the mDNS lookup search for other nodes.
        # usualy, it'll just be the same as your ipv4_address_iface
        lookup_bridge: eno0
        # [optional]
        #if you're setting up ceph, you must specify at least 3 volumes ( min 1 per node)
        ceph_volume_paths:
          - path: /dev/sda
            wipe: true
        # provider: azure # only specify this field if you want to use the networking strategy of a supported cloud provider instead of the default.
      192.168.0.145:
        ceph_volume_paths:
          - path: /dev/sda
            wipe: true
        hostname: rpi-1
        index_key: 1
        ipv4_address: 192.168.0.145
        ipv4_address_iface: eth0
        ipv4_address_private: 192.168.0.145
        ipv4_address_private_iface: eth0
        local_volume_path: /dev/sdb
        lookup_bridge: eth0
        # provider: azure
      192.168.0.147:
        ceph_volume_paths:
          - path: /dev/sda
            wipe: true
        hostname: orangepi4-lts-0
        index_key: 2
        ipv4_address: 192.168.0.147
        ipv4_address_iface: eth0
        ipv4_address_private: 192.168.0.147
        ipv4_address_private_iface: eth0
        local_volume_path: /dev/mmcblk0
        lookup_bridge: eth0
        # provider: azure
      host.example.com:
        hostname: micro-vm-1
        index_key: 3
        ipv4_address: 192.168.0.146
        ipv4_address_iface: eth0
        ipv4_address_private: 192.168.0.146
        ipv4_address_private_iface: eth0
        local_volume_path: /dev/mmcblk0
        lookup_bridge: eth0
        # provider: azure
        # you can specify other variables as you wish
        http_port: 80
        maxRequestsPerChild: 808
      # The below will not be supported because you will not be able to
      # specify the hostname for it
      # www[01:50].example.com:
    quantity: 3 # has no effect
```
> Important: This project is currently has only been tested successfully on ubuntu 22.04 LTS, ubuntu 24.04 LTS.

> **Very Important**: No matter the approach you take to create your compute resources,
you must **ensure they are visible to each other over a local/private network!**



## Deployment
On the sweet part.
- Open a terminal in the root of this project.
 > Important: ensure you
have the task package installed.
- To get the list of available tasks you can run `task --list`
- To deploy microcloud for a specific environment/group,
you'll can to run commands in the below formats:

```shell
task infra-create-<group>
task run-deploy-cache-<group> # basically just update_cache, you don't need to run this all the time.
task run-deploy-init-<group>
task run-deploy-install-<group>
```
eg.
``` shell
task infra-create-dev
task run-deploy-cache-dev
task run-deploy-init-dev
task run-deploy-install-dev
```

- To run all activities you can use the below command.
```shell
task microcloud-<group>-up
```
You can use this to setup multiple environments quickly.

eg.
```shell
task microcloud-dev-up &
task microcloud-test-up &
task microcloud-sit-up &
```
> You should probably start off using the individual commands until you're confident
that the up command will run all through without hicupps.

- To preview the list of ansible tasks that will be run in the microcloud
installation process and the hosts that will be affected,
you can run a command in this format: `task list-deploy-init-<group> && task task list-deploy-install-<group>`.
eg.
``` shell
task list-deploy-init-all && task task list-deploy-install-all
```
- If there is a failure after some resources have been created, you can fix
whatever caused the failure and run the below command formats:
```shell
task microcloud-<group>-up
# or the below three
task infra-refresh-<group>
task run-deploy-init-<group>
task run-deploy-install-<group>
```
> You can use the `-- -auto-approve` arguments in the infra commands to skip terraform prompts.
- After infra setup, if you want to see the list of IPs in a summarized form
simply run your `task infra-create-<group>` command again.

- If you wish to undo the microcloud installation you can run the below command format.
``` shell
task deploy-rollback-<group>
```
- To tear down the infra created using this project or remove a reference to an existing infra, simply run command of the below format: 
``` shell
task microcloud-<group>-down
```

## Extra Configuration

### Preseed
microcloud initialization supports a non interactive setup using a preseed.
See [example](https://canonical-microcloud.readthedocs-hosted.com/en/latest/how-to/initialise/#howto-initialise-preseed).

- If you want this project to setup all requirements for microcloud installation but you don't want
it to run `microcloud init` for you, then set `use_preseed: false` anywhere it can be read as an ansible variable eg. inside `all.yml` or `<group>.yml`.

For this project, you only need to configure `ovn`. Fields like `systems` and `storage` will be automatically populated based on other fields that you have provided.

## To-Do
- [ ] Add group_vars validation using CUElang
- [ ] Complete setup test on digital_ocean
- [ ] Complete setup test on oracle_cloud
- [ ] Complete setup test on aliyun
- [ ] Add support for ibm_cloud
- [ ] Add support for aws

## Community

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
