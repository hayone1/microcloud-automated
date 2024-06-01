# Microcloud Automated

<!-- [![GitHub Issues](https://img.shields.io/github/issues/acch/ansible-boilerplate.svg)](https://github.com/acch/ansible-boilerplate/issues) [![GitHub Stars](https://img.shields.io/github/stars/acch/ansible-boilerplate.svg?label=github%20%E2%98%85)](https://github.com/acch/ansible-boilerplate/) [![License](https://img.shields.io/github/license/acch/ansible-boilerplate.svg)](LICENSE) -->

[Micro Cloud](https://canonical-microcloud.readthedocs-hosted.com/en/latest/) allows you to deploy your own fully functional private cloud in minutes.

This project is generally intended for experimentation/evaluation and can be improved/customized to fit your unique needs to become production ready.

This project has 2 sections that can be independently depoyed and managed. They are
1. Deploying networked compute to various cloud providers in an opinionated yet flexible way.
2. Deploying microcloud on said compute.

## 1. Getting-Started

Download (clone) or fork this repository.
The major places of interest for customization will be in the [group_vars](group_vars/) folder.

### 1.1 Pre-requisites
- [yq 4.x](https://github.com/mikefarah/yq/#install)
- [jq](https://jqlang.github.io/jq/download/)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [taskfile](https://taskfile.dev/installation/)
- [faketime](https://manpages.ubuntu.com/manpages/trusty/man1/faketime.1.html)
- Ensure your system time is correct and `date -u` gives the correct utc time!

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
- In each group/environment specific file, specify the `group_name`, `ansible_user:`, `ansible_ssh_public_key_file:`, `ansible_ssh_private_key_file:` and `infra_providers` you are interested in deploying compute to.
For `infra_providers` You can use arbitrary values or one of the supported cloud providers of this project.

eg.
``` yaml
ansible_user: root
infra_providers:
  self_hosted:
  digital_ocean:
```
> Currently supported cloud providers are: `digital_ocean`, `azure`.

- If using a supported cloud provider, you can specify the `size`, `quantity:` and `region:`, `cephfs_volume_size`, `ceph_volume_size` and more under the cloud provider's field.
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
    custom_sizes: ["t2.micro"]
    # number of servers to be provisioned
    quantity: 3
    # see valid regions here https://slugs.do-api.dev/
    region: "nyc3"
```
- If you specify `size: custom` in a provider, you must declear the  `custom_sizes:` list.
It's best to either make the `custom_sizes:` list have only one entry or entries equal to
`quantity:`.
> If your `custom_sizes:` list length is less than the `quantity:` value, then the remaining
servers will be assigned the size of the last entry in your `custom_sizes:` list.
This gives room for some interesting customizations on the size options you may want to configure.

- If you have already setup your compute by yourself or used a provivder 
that is not yet supported, then you'd only need to specify the `hosts:` field.

  This is essentially ansible hosts config so you can put any valid ansible hosts value. See [examples](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html).
``` yaml
infra_providers:
  self_hosted:
    hosts:  # only host field will be used if specified
      # hostname and ipv4_address_private are manatory
      10.1.1.0: # public IP
        # local ip in subnet form
        ipv4_address_private: "192.168.20.50/24" # [mandatory]
        hostname: micro-vm-0 # [mandatory]
      # where ipv4_address_private is not specified like the below,
      # the IP key(s) will be considered for both public
      # and private IP use
      64.18.0.1:
        hostname: micro-ec-0
        ipv4_address_private: "192.168.20.55/24"
        # you can specify volume names (as seen from lsblk)
        ceph_volume: sdb # for distributed storage
        local_volume: sda # for local storage
      host.example.com:
        hostname: micro-vm-1
        ipv4_address_private: "192.168.30.51/24"
        # you can specify other variables as you wish
        http_port: 80
        maxRequestsPerChild: 808
      # The below will not be supported because you will not be able to
      # specify the hostname for it
      # www[01:50].example.com:
    quantity: 3 # has no effect
```
> Important: This project is currently only tested on **ubuntu** 22.04 LTS..

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

> **Very Important**: No matter the approach you take to create your compute resources,
you must **ensure they are visible to each other over a local or private network!**

> If you get an error saying your `id_rsa` permissions are too open, you may want to changr it's permission using a comand like `chmod 600 ~/.ssh/id_rsa`.

## 2 Deployment<a id='2'></a>
- Open a terminal in the root of this project and ensure you
have the task package installed.
- To get the list of available tasks you can run `task --list`
- To deploy microcloud for a specific environment/group,
you'll can to run commands in the below formats:

```shell
task microcloud-<group>-up
# or the below three
task infra-create-<group>
task run-deploy-init-<group>
task run-deploy-install-<group>
```
eg.
``` shell
task microcloud-dev-up
# or the below three
task infra-create-dev
task run-deploy-init-dev
task run-deploy-install-dev
```
<!-- - To deploy microcloud on all the environments/groups specified in the `all.yml`, simply run the below:
``` shell
task microcloud-all-up
# or the below three
task infra-create-all
task run-deploy-init-all
task run-deploy-install-all -->

<!-- - To preview the list of bash commands that will be run in the microcloud
installation process, just add `--dry` to any command you use.
eg.
``` shell
task microcloud-dev-up --dry
task infra-destroy-dev --dry
``` -->


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

- To rollback or destroy the deployments, simply run commands of the below format: 
``` bash
task destroy-infra-<group>
task destroy-microcloud-<group>
```
eg.
``` bash
task destroy-infra-all
task destroy-microcloud-all
```

## 3 Extra Configuration<a id='3'></a>

### 3.1 Preseed
microcloud initialization supports a non interactive setup using a preseed.
See [example](https://canonical-microcloud.readthedocs-hosted.com/en/latest/how-to/initialise/#howto-initialise-preseed).

For this project, you only need to configure `ovn`. Other fields like `systems` and `storage` will be automatically populated based on other fields that you have provided.

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

## 5 Maintainers<a id='5'></a>
- Boluwatife @hayone1
- Deborah @Debby77

## 6 Copyright and license<a id='6'></a>

This project is released under the [GNU GPLv3](LICENSE)
