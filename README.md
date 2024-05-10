# Microcloud Automated

<!-- [![GitHub Issues](https://img.shields.io/github/issues/acch/ansible-boilerplate.svg)](https://github.com/acch/ansible-boilerplate/issues) [![GitHub Stars](https://img.shields.io/github/stars/acch/ansible-boilerplate.svg?label=github%20%E2%98%85)](https://github.com/acch/ansible-boilerplate/) [![License](https://img.shields.io/github/license/acch/ansible-boilerplate.svg)](LICENSE) -->

[Micro Cloud](https://canonical-microcloud.readthedocs-hosted.com/en/latest/) allows you to deploy your own fully functional private cloud in minutes.

This project is generally intended for experimentation/evaluation and can be improved/customized to fit your unique needs to become production ready.


## 1. Getting-Started

Download (clone) or fork this repository.
The major places of interest for customization will be in the [group_vars](xxx) folder.

### 1.1 Pre-requisites
- [yq](https://github.com/mikefarah/yq/#install)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

To-Do: link to infra folder
### 1.2 Infra
To setup microcloud you will need to have compute and network resources. This could be from a cloud provider or your private servers.

- Inside the [group_vars](xxx) folder, edit the `all.yml` file, and specify the environments you're interested in setting-up under the `groups:` field. Arbitrary values are allowed
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
- In each group/environment specific file, specify the `ansible_user:` and `infra_provider` you are interested in deploying compute to. You can deploy arbitrary values or one of the supported cloud providers of this project.

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
```

- If you have already setup your compute by yourself or used a provivder that is not supported, then you'll need to specify the `hosts` alone.

  This is essentially ansible hosts config so you can input any valid ansible hosts value. See [here](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html).
``` yaml
infra_providers:
  self_hosted:
    hosts:  # only host field will be used
      host.example.com:
        http_port: 80
        maxRequestsPerChild: 808
      www[01:50].example.com:
    quantity: 3 # has not effect
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

- Take a detour and head over to the [infra-template](xxx) folder and locate the sub folder(s) of the infra_provider(s) you chose and go through their respective README(s).

  If your cloud provider is not one of the supported providers, then go through the README in the [others](xxx) sub folder.
  When you are done, you can continue with the next step.
  ___

- Once details of your cloud provider(s) has been provided. Run the below command to set up your compute.
```
task infra-deploy
```
> You can pass in valid terraform apply args by specifying them after "--" and separated by space.
eg. `task infra-deploy -- -auto-approve` 


## 2 Deployment<a id='2'></a>

## Using Ansible

Install `ansible` on your laptop and link the `hosts` file from `/etc/ansible/hosts` to the file in your repository. Now you're all set.

To run a single (ad-hoc) task on multiple servers:

```
# Check connectivity
ansible all -m ping -u root

# Run single command on all servers
ansible all -m command -a "cat /etc/hosts" -u root

# Run single command only on servers in specific group
ansible anygroup -m command -a "cat /etc/hosts" -u root

# Run single command on individual server
ansible server1 -m command -a "cat /etc/hosts" -u root
```

As the `command` module is the default, it can also be omitted:

```
ansible server1 -a "cat /etc/hosts" -u root
```

To use shell variables on the remote server, use the `shell` module instead of `command`, and use single quotes for the argument:

```
ansible server1 -m shell -a 'echo $HOSTNAME' -u root
```

The true power of ansible comes with so called *playbooks* &mdash; think of them as scripts, but they're declarative. Playbooks allow for running multiple tasks on any number of servers, as defined in the configuration files (`*.yml`):

```
# Run all tasks on all servers
ansible-playbook site.yml -v

# Run all tasks only on group of servers
ansible-playbook anygroup.yml -v

# Run all tasks only on individual server
ansible-playbook site.yml -v -l server1
```

Note that `-v` produces verbose output. `-vv` and `-vvv` are also available for even more (debug) output.

To verify what tasks would do without changing the actual configuration, use the `--list-hosts` and `--check` parameters:

```
# Show hosts that would be affected by playbook
ansible-playbook site.yml --list-hosts

# Perform dry-run to see what tasks would do
ansible-playbook site.yml -v --check
```

Running all tasks in a playbook may take a long time. *Tags* are available to organize tasks so one can only run specific tasks to configure a certain component:

```
# Show list of available tags
ansible-playbook site.yml --list-tags

# Only run tasks required to configure DNS
ansible-playbook site.yml -v -t dns
```

Note that the above command requires you to have tasks defined with the `tags: dns` attribute.

## Configuration files

The `hosts` file defines all hosts and groups which they belong to. Note that a single host can be member of multiple groups. Define groups for each rack, for each network, or for each environment (e.g. production vs. test).

### Playbooks

Playbooks associate hosts (groups) with roles. Define a separate playbook for each of your groups, and then import all playbooks in the main `site.yml` playbook.

File | Description
---- | -----------
`site.yml` | Main playbook - runs all tasks on all servers
`anygroup.yml` | Group playbook - runs all tasks on servers in group *anygroup*

### Roles

The group playbooks (e.g. `anygroup.yml`) simply associate hosts with roles. Actual tasks are defined in these roles:

```
roles/
├── common/             Applied to all servers
│   ├── handlers/
│   ├── tasks/
│   │   └ main.yml      Tasks for all servers
│   └── templates/
└── anyrole/            Applied to servers in specific group(s)
    ├── handlers/
    ├── tasks/
    │   └ main.yml      Tasks for specific group(s)
    └── templates/
```

Consider adding separate roles for different applications (e.g. webservers, dbservers, hypervisors, etc.), or for different responsibilities which servers fulfill (e.g. infra_server vs. infra_client).

### Tags

Use the following command to show a list of available tags:

```
ansible-playbook site.yml --list-tags
```

Consider adding tags for individual components (e.g. DNS, NTP, HTTP, etc.).

Role | Tags
--- | ---
Common | all,check

## Copyright and license

Copyright 2017 Achim Christ, released under the [MIT license](LICENSE)
