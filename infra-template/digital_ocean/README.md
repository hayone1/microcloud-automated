# INFRA SETUP digital_ocean

**Welcome**, the digital ocean infra setup.

## Setting-Up
> You can follow [this link](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean) to get a basic idea of this provider.

- Ensure the `ansible_user:`, `ansible_ssh_public_key_file`, and `ansible_ssh_private_key_file:` have been set in your `<group-name>.yml` file.
> **Important**: The SSH key shouldn't already exist on your digital ocean account, else provisioning will fail with an "SSH Key is already in use" error.

- Register on Digital ocean and create a personal access key with read and write permission.
See how to create [**here** (`digitalOcean`)](https://docs.digitalocean.com/reference/api/create-personal-access-token/)
- Export your Digital Ocean Personal Access Token to an environment variable. Name the variable `TF_VAR_DO_PAT` eg.
```
export TF_VAR_DO_PAT="your_personal_access_token"
```
- If you don't want to export the variable all the time, you can create one of the following env files(priority is as listed) and put the environment variable there:
    - `<group-name>.env` file in the `group_vars` folder eg. dev.env(Highest priority).
    - `.env` file in the `group_vars` folder.
    - `.env` file at the root of the project (lowest priority).
> Tip: .env files don't need double quotes.

- You can return back to the main [README](xxx) to complete the setup.
___



<!-- - Set the name of the ssh key you created in the `ssh_key_name:` field of each of your desired environments.
eg. (if the key name is `root_ssh`) -->
<!-- ``` yaml
...
ssh_key_name: root_ssh
...
``` -->