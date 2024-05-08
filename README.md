# Microcloud Automated

<!-- [![GitHub Issues](https://img.shields.io/github/issues/acch/ansible-boilerplate.svg)](https://github.com/acch/ansible-boilerplate/issues) [![GitHub Stars](https://img.shields.io/github/stars/acch/ansible-boilerplate.svg?label=github%20%E2%98%85)](https://github.com/acch/ansible-boilerplate/) [![License](https://img.shields.io/github/license/acch/ansible-boilerplate.svg)](LICENSE) -->

[Micro Cloud](https://canonical-microcloud.readthedocs-hosted.com/en/latest/) allows you to deploy your own fully functional private cloud in minutes.

This project is generally intended for experimentation/evaluation and can be improved/customized to fit your unique needs to become production ready.


## 1. Getting-Started

Download (clone) or fork this repository.
The major places of interest for customization will be in the [group_vars](xxx) folder as well as the `hosts.yml` file.

### 1.1 Pre-requisites
- [yq](https://github.com/mikefarah/yq/#install)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

To-Do: link to infra folder
### 1.2 Infra
To setup microcloud you will need to have compute and network resources. This could be from a cloud provider or your private servers.


- Inside the [group_vars](xxx) folder, edit the `infra-providers` field of the `all.yml` file and specify the cloud provider(s) you are interested in deploying compute to. You can put any arbitrary value or one of the supported ones for automated compute deployment `digital_ocean`.
eg.
```
infra_providers:
  - digital_ocean
  - self_hosted
  - ibm_cloud
```
> Important: Only alpha-numeric and characters underscore(_) are supported.

- In the `all.yml` file, also specify the environments you're interested in setting-up under the `groups:` field.
 eg.
```
groups:
  - dev
  - uat
```

- In the same [group_vars](xxx) folder, duplicate the `dev.yml` to match the number of items/environments you have in the all.yaml `groups:` field and rename each file to match the items in the groups.
eg.
```
dev.yml
uat.yml
```
> You can create as many environment specific yaml files as you want, but only the ones specified in the groups field will be considered in the automated script.

<!-- - At this point, **if you only chose self_hosted or any other unsupported value in your infra_providers**, then you can jump to the [deployment](#2) section. -->

- Take a detour and head over to the [infra-template](xxx) and locate the folder(s) of the infra_providers you chose. Go through their respective README(s).

  If your cloud provider is not one of the supported providers, then go through the README in the [others](xxx) folder.
  When you are done, you can continue with the next step.

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
