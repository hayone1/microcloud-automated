# INFRA SETUP digital_ocean

> You can follow [this link](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean) if you would like to setup this folder yourself.

**Welcome**, the digital ocean infra setup.

## Setting-Up
- Register on Digital ocean and create a personal access key with read and write permission.
See how to create [**here** (`digitalOcean`)](https://docs.digitalocean.com/reference/api/create-personal-access-token/)
- Export your Digital Ocean Personal Access Token to an environment variable. Name the variable `DO_PAT` eg.
```
export DO_PAT="your_personal_access_token"
```
- If you don't want to export the variable all the time, you can create one of the following env files(priority is as listed) and put the environment variable there:
    - `<env-name>.env` file in the `group_vars` folder eg. dev.env(Highest priority).
    - `.env` file in the `group_vars` folder.
    - `.env` file at the root of the project (lowest priority).
> Tip: .env files don't need double quotes.

- You can return back to the main [README](xxx) to complete the setup.
___

The terraform script aut-generates temporary ssh keys. If you would like to create your ssh keys manually.
See how to do so [**here**](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-team/).

This would however require you to personally edit the `infra.tf` file to use your generated ssh keys. See [how](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean).

<!-- - Set the name of the ssh key you created in the `ssh_key_name:` field of each of your desired environments.
eg. (if the key name is `root_ssh`) -->
<!-- ``` yaml
...
ssh_key_name: root_ssh
...
``` -->