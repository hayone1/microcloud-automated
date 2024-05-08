**Welcome** to the others infra setup.

## Setting-Up
- From your cloud provider, create virtual machine instances and grab their IPs.

> Important: The virtual machines must be visible to each other over a local/private network.

- In the group_vars folder, locate the environment/group specific yaml files you created earlier (eg. dev.yml) and create a field in each file matching the name of your infra_provider.
eg.
``` yaml
self_hosted:
ibm_cloud:
```

- Under each entry, specify the associated IPs you fetched earlier.
eg.

dev.yml
``` yaml
ibm_cloud:
    - ip: 209.85.128.0
    - ip: 209.85.128.1
```

uat.yml
``` yaml
self_hosted:
    - ip: 64.233.160.0
    - ip: 64.233.160.1
ibm_cloud:
    - ip: 216.239.32.0
    - ip: 216.239.32.1
```
> Important: All IPs should be unique.

- You can return back to the main [README](xxx) to complete the setup.