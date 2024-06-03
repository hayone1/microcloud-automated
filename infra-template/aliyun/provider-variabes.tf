# return the same size for each server up to the quntity specified
locals {
  server_sizes = {
    "nano"     = [for _ in range(0, local.provider_config.quantity) : "ecs.t5-lc1m2.small"] 
    "micro"    = [for _ in range(0, local.provider_config.quantity) : "ecs.g8y.small"]
    "small"    = [for _ in range(0, local.provider_config.quantity) : "ecs.t5-lc1m2.large"]
    # pricing danger zone
    "medium"   = [for _ in range(0, local.provider_config.quantity) : "ecs.c6.large"]
    "large"    = [for _ in range(0, local.provider_config.quantity) : "ecs.c6.xlarge"]
    "xlarge"   = [for _ in range(0, local.provider_config.quantity) : "ecs.c6.2xlarge"]
    "2xlarge"  = [for _ in range(0, local.provider_config.quantity) : "ecs.c6.4xlarge"]
    "custom"  = local.custom_size_map
  }

  selected_server_sizes = (
    local.server_sizes[ (local.group_config.infra_providers[local.folder_name].size) ]
  )
}

# The data disk category used to launch one or more data disks.
# eg. cloud,cloud_efficiency,cloud_ssd,cloud_essd
# see https://www.alibabacloud.com/help/en/ecs/developer-reference/api-ecs-2014-05-26-createdisk?spm=a2c63.p38356.0.0.7fd92afaFvJxd7
locals {
  disk_category = try(
    local.provider_config.disk_category,
    "cloud_efficiency"
  )
  instance_charge_type = try(
    local.provider_config.instance_charge_type,
    "PostPaid"
  )
  internet_max_bandwidth_out = try(
    local.provider_config.internet_max_bandwidth_out,
    "10"
  )
  internet_charge_type = try(
    local.provider_config.internet_charge_type,
    "PayByTraffic"
  )
  system_disk_category = try(
    local.provider_config.system_disk_category,
    "PayByTraffic"
  )
  delete_auto_snapshot = try(
    local.provider_config.delete_auto_snapshot,
    true
  )
  enable_auto_snapshot = try(
    local.provider_config.enable_auto_snapshot,
    false
  )
  encrypted = try(
    local.provider_config.encrypted,
    false
  )
  # delete_auto_snapshot = "true"
  # enable_auto_snapshot = "true"
  # encrypted            = "true"
}

// Zones data source for availability_zone
// Will be an jagged array
data "alicloud_zones" "avzones" {
  count = length(local.selected_server_sizes)
  available_disk_category = local.disk_category
  available_instance_type = local.selected_server_sizes[count.index]
}

// Images data source for image_id
data "alicloud_images" "available-images" {
  most_recent = true
  owners      = try(
    local.provider_config.image.owners,
    local.provider_config.image.publisher,
  )
  name_regex  = try(
    local.provider_config.image.name_regex,
    local.provider_config.image.sku,
  )
}

locals {
  chosen_availability_zone = (
    local.provider_config.availability_zone == "auto" ?
        # the index is hard coded
        data.alicloud_zones.avzones.zones[0].id :
        local.provider_config.availability_zone
  )
}


variable "ANSIBLE_SSH_PASS" {
  type = string
}



#===============

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