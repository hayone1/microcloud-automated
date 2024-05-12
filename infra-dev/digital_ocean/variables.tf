# value will be passed at runtime
# var.group will be provided from cli -var 'group=group_name'

locals {
  # get environment name from parent folder
  parent_path = abspath("${path.module}")
  folder_name = basename(local.parent_path)
  parent_folder_name = basename(dirname(local.parent_path))
  # group si synonymous to environment here
  group = split("-", local.parent_folder_name)[1] # eg. dev

  # read ansible group_vars related to this group/environment
  # eg. read group_vars/dev.yaml
  group_config  = yamldecode(file("../../group_vars/${local.group}.yml"))
  provider_config = local.group_config.infra_providers[local.folder_name]

  prefix = local.group_config.prefix
}

locals {

  # give each server's size it's own indexed entry from the cusom_size list
  # else set all sizes to the first item if the quantity doesnt match the cusom_size list length
  custom_size_map = length(local.provider_config.custom_size) == local.provider_config.quantity ? [
    for i in range(
      0, local.provider_config.quantity) : local.provider_config.custom_size[i]
  ] : [
    for i in range(
      0, local.provider_config.quantity) : local.provider_config.custom_size[0]
  ]
}




locals {
  server_sizes = {
    "nano"     = [for _ in range(0, local.provider_config.quantity) : "s-1vcpu-1gb"] 
    "micro"    = [for _ in range(0, local.provider_config.quantity) : "s-2vcpu-2gb"]
    "small"    = [for _ in range(0, local.provider_config.quantity) : "s-2vcpu-4gb"]
    # pricing danger zone
    "medium"   = [for _ in range(0, local.provider_config.quantity) : "g-2vcpu-8gb"]
    "large"    = [for _ in range(0, local.provider_config.quantity) : "g-4vcpu-16gb"]
    "xlarge"   = [for _ in range(0, local.provider_config.quantity) : "g-8vcpu-32gb"]
    "2xlarge"  = [for _ in range(0, local.provider_config.quantity) : "g-16vcpu-64gb"]
    "custom"  = local.custom_size_map
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