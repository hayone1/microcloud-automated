# INFRA SETUP azure

**Welcome**, the azure infra setup.

## Getting Started



> You can follow [this link](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-provider/01-summary.htm)
to get a basic idea of how to setup this provider or if you encounter issues with this guide.
> **Important**: This project does not work well with the oracle free tier's limitations.

|Tested OS|
|---------|
|Ubuntu-22-04-lts|

This project uses oci API key based authentication.
There are 3 major preparatory stages for OCI.
- [Create RSA Keys](#create-rsa-keys)
- [Add List Policy](#add-list-policy)
- [Gather Required Information](#gather-required-information)

### Create RSA Keys
**You can skip this section if you have already added your RSA keys to Oracle cloud.**

- Create an account on [oracle cloud](https://www.oracle.com/cloud/).
- Under your home directory, make an .oci directory.
``` shell
mkdir ~/.oci
```
> **Important**: If you're using Windows Subsystem for Linux (WSL), create the /.oci directory directly in the Linux environment. If you create the /.oci directory in a /mnt folder (Windows file system), you're required to use the chmod command to change permissions for the WSL configuration files.

- Generate a 2048-bit private key in a PEM format.
eg.
``` shell
openssl genrsa -out $HOME/.oci/microcloud_oci.pem 2048
```
- Change permissions, so only you can read and write to the private key file.
eg.
``` shell
chmod 600 $HOME/.oci/microcloud_oci.pem
```
- Generate the public key.
eg.
```
openssl rsa -pubout -in $HOME/.oci/microcloud_oci.pem -out $HOME/.oci/microcloud_oci_public.pem
```
- Copy the public key. You can vieew it by running
``` shell
cat $HOME/.oci/microcloud_oci_public.pem
```
- Add the public key to your user account.
    * In the OCI Console's top right navigation bar, click the Profile menu, and then go to User settings.
    * Click API Keys.
    * Click Add API Key.
    * Select Paste Public Keys.
    * Paste value from previous step, including the lines with BEGIN PUBLIC KEY and END PUBLIC KEY.
    * Click Add.
- A configuration file snippet will be presented, copy it.

### Gather Required Information
- A configuration file snippet will be presented which includes the basic authentication information you'll
need to use the SDK, CLI, or other OCI developer tool. It may begin with a `[DEFAULT]` text.
- Export the contents of the text as environment variables. eg
``` shell
export TF_VAR_tenancy_ocid=xxxxx
export TF_VAR_user_ocid=xxxxxx
export TF_VAR_fingerprint=xxxxx
export TF_VAR_private_key_path=xxxxxx # this should be the path to your RSA key .pem file
export TF_VAR_region=xxxxxxxxx
```
- If you don't want to export the variable all the time, you can create one of the following env files(priority is as listed) and put the environment variables there:
    - `<group-name>.env` file in the `group_vars` folder eg. dev.env(Highest priority).
    - `.env` file in the `group_vars` folder.
    - `.env` file at the root of the project (lowest priority).
The content will look like this:
```
TF_VAR_tenancy_ocid=xxxxx
TF_VAR_user_ocid=xxxxxx
TF_VAR_fingerprint=xxxxx
TF_VAR_private_key_path=xxxxxx
TF_VAR_region=xxxxxxxxx
```
> Tip: .env files don't need double quotes.
#### Alternative way to gather information
1. Collect the following credential information from the OCI Console.
    - Tenancy OCID: <tenancy-ocid>
        * In the top navigation bar, click the Profile menu, go to Tenancy: <your-tenancy> and copy OCID.
    - User OCID: <user-ocid>
        * From the Profile menu, go to User settings and copy OCID.
    - Fingerprint: <fingerprint>
        * From the Profile menu, go to User settings and click API Keys.
        * Copy the fingerprint associated with the RSA public key you made in the previous section.
        The will appear like: xx:xx:xx...xx.
    - Region: <region-identifier>
        * From the top navigation bar, find your region.
        * From the table in `Regions and Availability Domains`, Find your region's <region-identifier>. Example: us-ashburn-1.
2. Collect the following information from your environment.
    - Private Key Path: <rsa-private-key-path>
        * Path to the RSA private key you made in the Create RSA Keys section.
        eg. `~/.oci/microcloud_oci.pem`


### Add List Policy
> If your username is in the Administrators group, then skip this step,
otherwise, ask your administrator to add the appropriate list policy to your tenancy.
- You can follow[this link](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-provider/01-summary.htm#)
to see how to do so.
- You can return back to the main [README](../../README.md) to complete the setup.

___

## More Info
- If you get a resource not found or out of hosts error, you may need to manually specify your
`availability_domain:` in your <group-name>.yml to accomodate the compute to be deployed.
eg.
```

```
- [Terraform OCI setup](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-provider/01-summary.htm)
- For a list of valid regions see [here](https://github.com/claranet/terraform-azurerm-regions/blob/master/regions.tf)
- For how to see valid VM images, see [here](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage)

| References|
|-----------|
| https://github.com/oracle/terraform-provider-oci/tree/master/examples |
| https://github.com/RhubarbSin/terraform-oci-free-compute-maximal-example/tree/main |

