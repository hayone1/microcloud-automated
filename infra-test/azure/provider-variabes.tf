# return the same size for each server up to the quntity specified
locals {
  server_sizes = {
    "nano"     = [for _ in range(0, local.provider_config.quantity) : "Standard_B1s"] 
    "micro"    = [for _ in range(0, local.provider_config.quantity) : "Standard_B2s"]
    "small"    = [for _ in range(0, local.provider_config.quantity) : "Standard_D2s_v3"]
    # pricing danger zone
    "medium"   = [for _ in range(0, local.provider_config.quantity) : "Standard_D4s_v3"]
    "large"    = [for _ in range(0, local.provider_config.quantity) : "Standard_D8s_v3"]
    "xlarge"   = [for _ in range(0, local.provider_config.quantity) : "Standard_D16s_v3"]
    "2xlarge"  = [for _ in range(0, local.provider_config.quantity) : "Standard_D32s_v3"]
    "custom"  = local.custom_size_map
  }

  selected_server_sizes = (
    local.server_sizes[
      local.group_config.infra_providers[local.folder_name].size
      ]
  )
}


# variable "ARM_SUBSCRIPTION_ID" {
#   type        = string
#   description = "Azure subscription id under which resources will be provisioned"
# }

# variable "ARM_CLIENT_ID" {
#   type        = string
#   description = "Azure client id used to create resources"
# }

# variable "ARM_CLIENT_SECRET" {
#   type        = string
#   description = "Client secret used to authenticate with Azure apis"
# }

# variable "ARM_TENANT_ID" {
#   type        = string
#   description = "Azure tenant id used to create resources"
# }

# variable "local_address_subnet" {
#     type = list(string)
#     description = "value"
# }

variable "storage-account-type" {
    type = string
    description = "The general storage account type to use for storages"
    default = "StandardSSD_LRS"
    # default = "Premium_LRS"
}
variable "storage-caching" {
    type = string
    description = "The general caching requirements to use for storages"
    default = "ReadWrite"
}