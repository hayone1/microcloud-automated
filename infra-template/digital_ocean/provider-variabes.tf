
##### provider specific variables ##### 
variable "DO_PAT" {
  type        = string
  description = "Provider specific API token/key used for TF authentication."
}
# variable "pvt_key" {}
##### provider specific variables ##### 

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

  selected_server_sizes = (
    local.server_sizes[
      local.group_config.infra_providers[local.folder_name].size
      ]
  )
}

locals {
  initial_filesystem_type = try(local.provider_config.initial_filesystem_type, "xfs")
}