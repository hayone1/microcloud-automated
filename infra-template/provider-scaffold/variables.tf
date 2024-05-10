# value will be passed at runtime
# var.group will be provided from cli -var 'group=group_name'

locals {
  # get environment name from parent folder
  parent_path = abspath("${path.module}")
  folder_name = basename(local.parent_path)
  parent_folder_name = basename(dirname(local.parent_path))

  # It will be read when this template is automatically duplicated copied
  # into an env specific folder by the taskfile eg. ./infra-dev/digital_ocean
  # in this case, dev will be the group
  group = split("-", local.parent_folder_name)[1] # eg. dev
  # group is synonymous to environment here.

  # read ansible group_vars related to this group/environment
  # eg. read group_vars/dev.yaml
  group_config  = yamldecode(file("../../group_vars/${local.group}.yml"))

  prefix = "microcloud-"
}

# set slugs specific to cloud provider, all options
# should be set to a valid value
locals {
  server_sizes = {
    "nano"     = "s-1vcpu-1gb"
    "micro"    = "s-1vcpu-1gb"
    "small"    = "s-1vcpu-1gb"
    "medium"   = "s-2vcpu-2gb"
    "large"    = "s-4vcpu-8gb"
    "xlarge"   = "s-8vcpu-16gb"
    "2xlarge"  = "s-16vcpu-32gb"
    "custom"  = (
      local.group_config.infra_providers[local.folder_name].custom_size
    )
  }

  selected_server_size = (
    local.server_sizes[
      local.group_config.infra_providers[local.folder_name].size
      ]
  )
  server_user          = local.group_config.ansible_user
}

##### provider specific variables ##### 
variable "provider_token" {
  type        = string
  description = "Provider specific API token/key used for TF authentication."
}
# variable "pvt_key" {}
##### provider specific variables ##### 