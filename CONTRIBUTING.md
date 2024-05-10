# Contributing

microcloud-automated is [GNU GPLv3 Licensed](LICENSE) and
accepts contributions via GitHub pull requests. This document outlines
some of the conventions on to make it easier to get your contribution
accepted.

## Before you get started

- Please make sure to read and observe the
[Code of Conduct](CODE_OF_CONDUCT.md).

- You can also [Create an issue](https://github.com/hayone1/microcloud-automated/issues/new/choose): If you have noticed a bug or want to suggest a feature.

- If you simply want to ask a question or suggest a feature, you can [start or Join a discussion](https://github.com/hayone1/microcloud-automated/discussions). Otherwise, you can go ahead and [create an issue](hhttps://github.com/hayone1/microcloud-automated/issues/new/choose).

## Environment Setup

### Prerequisites
- [yq](https://github.com/mikefarah/yq/#install)
- [jq](https://jqlang.github.io/jq/download/)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [taskfile](https://taskfile.dev/installation/)

### Setup
- Clone or fork this repo.
- Start working
- Create a pull request when done

### Adding infra-provider template

If you want to add support automated compute provisioning for a cloud provider, you can duplicate and rename the [provider-scaffold](infra-template/provider-scaffold/) folder and begin editing.

The first place you would want to check is the (variables.tf)[variables.tf] file to see what variables are available.

The goals are to:
- provision infrastructure that are within the same subnet and/or are visible to eath other over a local/private network.
- Write an appropriate command(see [config.yml sample](config.yml)) that can extract the IPs into a comma separated string.


### Useful Links

| Month    |
| -------- |
| https://canonical-microcloud.readthedocs-hosted.com/en/latest/tutorial/get_started/  |
| https://developer.hashicorp.com/terraform/tutorials  |
| https://ydb.tech/docs/en/devops/ansible/preparing-vms-with-terraform |

### Important
Do not edit the root .gitignore file directly. Any pull requests with a change to the .gitignore file will be rejected.
If you want to update the file, you can instead open a discussion oor pull request to notify the maintainers of the benefits of doing so.

This avoids possible exposure and pushing of sensitive files into the repo that were
originally marked as ignore.