# return the same size for each server up to the quntity specified
locals {
  server_sizes = {
    "nano"     = [for _ in range(0, local.provider_config.quantity) : {shape = "VM.Standard.E2.1.Micro", ocpus = 1, memory_in_gbs = 1}] 
    "micro"    = [for _ in range(0, local.provider_config.quantity) : {shape = "VM.Standard.A1.Flex", ocpus = 2, memory_in_gbs = 2}]
    "small"    = [for _ in range(0, local.provider_config.quantity) : {shape = "VM.Standard.A1.Flex", ocpus = 2, memory_in_gbs = 4}]
    "medium"   = [for _ in range(0, local.provider_config.quantity) : {shape = "VM.Standard3.Flex", ocpus = 4, memory_in_gbs = 6}]
    "large"    = [for _ in range(0, local.provider_config.quantity) : {shape = "VM.Standard.E4.Flex", ocpus = 6, memory_in_gbs = 12}]
    "xlarge"   = [for _ in range(0, local.provider_config.quantity) : {shape = "VM.Standard.A1.Flex", ocpus = 8, memory_in_gbs = 16}]
    "2xlarge"  = [for _ in range(0, local.provider_config.quantity) : {shape = "VM.Standard.E5.Flex", ocpus = 12, memory_in_gbs = 32}]
    "custom"  = local.custom_size_map
  }

    # local.folder_name is same as group/env name
  selected_server_sizes = (
    local.server_sizes[ (local.group_config.infra_providers[local.folder_name].size) ]
  )
}

variable "tenancy_ocid" {
  type        = string
  description = "Oracle-assigned unique ID for Tenant."
}

variable "user_ocid" {
  type        = string
  description = "Oracle-assigned unique ID for User."
}

variable "private_key_path" {
  type        = string
  description = "Path to gnerated RSA keys pem file."
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint of generated RSA keys."
}

variable "region" {
    type = string
    description = "Region assigned to oci tenant."
}

data "oci_identity_availability_domains" "avdomains" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "available-images" {
  # for each shape, there will actually be a list of available images
  #i.e this data will be an jagged array
  # for_each        = toset(local.selected_server_sizes)
  count           = length(local.selected_server_sizes)
  compartment_id  = oci_identity_compartment.tf-compartment.id

  operating_system = try(
    local.provider_config.image.operating_system,
    local.provider_config.image.publisher
  )

  operating_system_version = try(
    local.provider_config.image.operating_system_version,
    local.provider_config.image.version
  )

  shape      = local.selected_server_sizes[count.index].shape
  sort_by    = "TIMECREATED"
  sort_order = "DESC"
  state      = "AVAILABLE"

  # filter {
  #   name   = "display_name"
  #   values = ["^Canonical-Ubuntu-([\\.0-9-]+)$"]
  #   regex  = true
  # }
}

locals {
  # "One or more data centers located within a region."
  chosen_availability_domain = (
    local.provider_config.availability_domain == "auto" ?
        data.oci_identity_availability_domains.avdomains.availability_domains[2].name :
        local.provider_config.availability_domain
  )

  ocids = [
    for i in range(0, local.provider_config.quantity) :
      local.provider_config.image.ocids[
        min(max(0,i), length(local.provider_config.image.ocids) - 1)
      ]
  ]

  selected_oci_core_images = [
    for idx, ocid in local.ocids: 
      ocid == "auto" ?
        data.oci_core_images.available-images[idx].images[0].id :
        ocid
  ]
}

locals {
  protocol_numbers = try(
    local.provider_config.protocol_numbers, 
    tomap({
      icmp   = 1
      icmpv6 = 58
      tcp    = 6
      udp    = 17
    })
  )
}