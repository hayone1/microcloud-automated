# value will be passed at runtime
# var.group will be provided from cli -var 'group=group_name'

locals {
  parent_path = abspath("${path.module}")
  folder_name = basename(local.parent_path)
  parent_folder_name = basename(dirname(local.parent_path))
  group = split("-", local.parent_folder_name)[1] # eg. dev

  group_config  = yamldecode(file("../../group_vars/${local.group}.yml"))
  provider_config = local.group_config.infra_providers[local.folder_name]

  prefix = try(local.group_config.prefix, "")
}

locals {

  custom_size_map = (
    try(length(local.provider_config.custom_sizes) > 0, false) ?
      [
        for i in range(0, local.provider_config.quantity) :
          local.provider_config.custom_sizes[
            min(max(0,i), length(local.provider_config.custom_sizes) - 1)
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

locals {
  allowed_ports = try(
    local.provider_config.security_rules.allowed_ports, 
    [22, 80, 443, 8443]
  )
  allowed_source_address_prefix = try(
    local.provider_config.security_rules.allowed_source_address_prefix, 
    "0.0.0.0/0"
  )
  allowed_destination_address_prefix = try(
    local.provider_config.security_rules.allowed_destination_address_prefix, 
    "0.0.0.0/0"
  )
}
