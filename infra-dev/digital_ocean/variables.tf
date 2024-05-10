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
}

locals {
  server_sizes = {
    "nano"     = "s-1vcpu-1gb"
    "micro"    = "s-1vcpu-1gb"
    "small"    = "s-1vcpu-1gb"
    "medium"   = "s-2vcpu-2gb"
    "large"    = "s-4vcpu-8gb"
    "xlarge"   = "s-8vcpu-16gb"
    "2xlarge"  = "s-16vcpu-32gb"
    "custom"  = "insert_custom_size"
  }

  selected_server_size = (
    local.server_sizes[
      local.group_config.infra_providers[local.folder_name].size
      ]
  )
  server_user          = local.group_config.ansible_user
}

variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "microcloud-"
}

# variable "server_size" {
#   type        = string
#   description = "Size used for server"
#   default     = local.selected_server_size
# }

##### provider specific variables ##### 
variable "provider_token" {
  type        = string
  description = "DigitalOcean API token used to create infrastructure"
}
# variable "pvt_key" {}
##### provider specific variables ##### 