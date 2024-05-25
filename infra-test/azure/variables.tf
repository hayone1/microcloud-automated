# value will be passed at runtime
# var.group will be provided from cli -var 'group=group_name'

locals {
  # get environment name from parent folder
  parent_path = abspath("${path.module}")
  folder_name = basename(local.parent_path)
  parent_folder_name = basename(dirname(local.parent_path))
  # group is synonymous to environment here
  group = split("-", local.parent_folder_name)[1] # eg. dev

  # read ansible group_vars related to this group/environment
  # eg. read group_vars/dev.yaml
  group_config  = yamldecode(file("../../group_vars/${local.group}.yml"))
  provider_config = local.group_config.infra_providers[local.folder_name]

  prefix = try(local.group_config.prefix, "")
}

locals {

  # assign server size from custom_size list
  # If custom_size list is smaller than server quantity,
  # then all extra servers will take the size of the last item in the custom_size list
  # if custom_size list is not defined or it is empty, then create a list of default sizes
  custom_size_map = (
    try(length(local.provider_config.custom_size) > 0, false) ?
      [
        for i in range(0, local.provider_config.quantity) :
          local.provider_config.custom_size[
            min(max(0,i), length(local.provider_config.custom_size) - 1)
          ]
      ] : []
  )
  local_volume_map = (
    try(length(local.provider_config.local_volume_sizes) > 0, false) ?
      [
        for i in range(0, local.provider_config.quantity) :
          local.provider_config.local_volume_sizes[
            min(max(0,i), length(local.provider_config.local_volume_sizes) - 1)
          ]
      ] : []
  )
  
  ceph_volume_map = (
    try(length(local.provider_config.ceph_volume_sizes) > 0, false) ?
      [
        for i in range(0, local.provider_config.quantity) :
          local.provider_config.ceph_volume_sizes[
            min(max(0,i), length(local.provider_config.ceph_volume_sizes) - 1)
          ]
      ] : []
  )
  tags = merge(
    try(local.group_config.tag, {}),
    try(local.provider_config.tag, {})
  )
  server_user          = local.group_config.ansible_user
}
