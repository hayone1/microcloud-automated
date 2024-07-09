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
- [yq 4.x](https://github.com/mikefarah/yq/#install)
- [jq](https://jqlang.github.io/jq/download/)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [taskfile](https://taskfile.dev/installation/)

### Setup
- Clone or fork this repo.
- Start working
- Create a pull request when done

### Adding infra-provider template

If you want to add support automated compute provisioning for a cloud provider, you can duplicate and rename
the [digital_ocean](infra-template/provider-scaffold/) folder and begin editing.
> Only underscore(_) is supported as a special character i the provider's name.


The first place you would want to check is the (variables.tf)[variables.tf] file to see what variables are available.

The goals are to:
- provision compute instances that are within the same subnet and/or are visible to eath other over
a local/private network.
- Create a terraform output called `ansible-hosts` with at minimum the public ipv4 address/url,
private ip address of the created instances.
ie.
``` tf
output "ansible-hosts" {
  value = {
    ...
  }
}
```
See [digital_ocean infra.yml sample](infra-template/digital_ocean/infra.tf)
 
A Valid Output would produce something like the below:

``` jsonc
"outputs": {
  ...
  "ansible-hosts": {
    "value": {
      // required: IP address or url
      "104.131.191.142": {
        // The volumes are the name of the volume as seen from
        // within the server itself (eg. when you run lsblk)
        "ceph_volume_paths": "/dev/sdb", // required for distributed storage
        "local_volume_path": "/dev/sda", // required for local storage
        "hostname": "micro-vm-0", //not required. as seen on the local network
        "index_key": 0, // not required, can be used for internal purposes
        "ipv4_address": "105.141.191.142", // not required
        "ipv4_address_private": "10.108.0.2/20" // required, Ip on the local network
      },
      "138.197.44.53": {
        "ceph_volume_paths": "/dev/sdb",
        "local_volume_path": "/dev/sda",
        "hostname": "micro-vm-1",
        "index_key": 1,
        "ipv4_address": "148.137.44.53",
        "ipv4_address_private": "10.108.0.4/20"
      }
    }
  }
}
```

  ### Useful Links

  | Link    |
  | -------- |
  | https://canonical-microcloud.readthedocs-hosted.com/en/latest/tutorial/get_started/  |
| https://developer.hashicorp.com/terraform/tutorials  |
| https://ydb.tech/docs/en/devops/ansible/preparing-vms-with-terraform |
| https://ericroc.how/lxd-networking.html |
| https://github.com/nehalineogi/azure-cross-solution-network-architectures/blob/main/advanced-linux-networking/linux-vxlan.md |
| https://luppeng.wordpress.com/2023/01/10/make-lxd-containers-visible-on-host-network/ |
| https://netplan.readthedocs.io/en/stable/examples/#how-to-configure-network-bridges |
| https://github.com/canonical/microcloud/issues/256 |
| https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/assembly_using-a-vxlan-to-create-a-virtual-layer-2-domain-for-vms_configuring-and-managing-networking#proc_proc_configuring-virtual-machines-to-use-vxlan_assembly_using-a-vxlan-to-create-a-virtual-layer-2-domain-for-vms | 
| https://gist.github.com/jimmydo/e4943950427234408a1aaa2d7beda8b6?permalink_comment_id=5069697#file-ubuntu-server-multicast-dns-md |
| https://www.digitalocean.com/community/tutorials/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server |

### Important
Do not edit the root .gitignore file directly. Any pull requests with a change to the .gitignore file will be rejected.
If you want to update the file, you can instead open a discussion oor pull request to notify the maintainers of the benefits of doing so.

This avoids possible exposure and pushing of sensitive files into the repo that were
originally marked as ignore.