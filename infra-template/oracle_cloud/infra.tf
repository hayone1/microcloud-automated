resource "oci_identity_compartment" "tf-compartment" {
    compartment_id  = var.tenancy_ocid
    description     = "Compartment for Terraform resources."
    name            = "${local.prefix}-compartment"

    enable_delete   = true 
}

resource "oci_core_virtual_network" "microcloud-vnet" {
    display_name    = "${local.prefix}-vnet"
    compartment_id  = oci_identity_compartment.tf-compartment.id

    cidr_block     = "10.0.0.0/16"
    dns_label       = "vnet"
}

resource "oci_core_security_list" "microcloud-security-list" {
    # manage_default_resource_id = oci_core_virtual_network.microcloud-vnet.default_security_list_id
    compartment_id = oci_identity_compartment.tf-compartment.id
    vcn_id            = oci_core_virtual_network.microcloud-vnet.id
    display_name = "${local.prefix}-security-list"
    dynamic "ingress_security_rules" {
        for_each = [22, 80, 443]
        iterator = port
        content {
            protocol = local.protocol_numbers.tcp
            source   = "0.0.0.0/0"

            description = "SSH and HTTPS traffic from any origin"

            tcp_options {
                max = port.value
                min = port.value
            }
        }
    }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.protocol_numbers.tcp
    # protocol    = "all"

    description = "All traffic to any destination"
  }
}

resource "oci_core_route_table" "microcloud-route-table" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_virtual_network.microcloud-vnet.id
  display_name   = "${local.prefix}-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.microcloud-internet-gateway.id
  }
}

resource "oci_core_subnet" "microcloud-subnet" {
    # same range as the virtual network itself
  display_name      = "${local.prefix}-subnet"
  compartment_id    = oci_identity_compartment.tf-compartment.id

  cidr_block        = oci_core_virtual_network.microcloud-vnet.cidr_block
  vcn_id            = oci_core_virtual_network.microcloud-vnet.id
  route_table_id    = oci_core_route_table.microcloud-route-table.id 
  security_list_ids = [oci_core_security_list.microcloud-security-list.id]
  dns_label         = "subnet" 
}

# resource "oci_core_network_security_group" "microcloud-nsg" {
#   compartment_id = oci_identity_compartment.tf-compartment.id
#   vcn_id         = oci_core_virtual_network.microcloud-vnet.id

#   display_name = "${local.prefix}-nsg"
# }

# resource "oci_core_network_security_group_security_rule" "microcloud-nsg-rule" {
#   direction                 = "INGRESS"
#   network_security_group_id = oci_core_network_security_group.microcloud-nsg.id
#   protocol                  = local.protocol_numbers.icmp
#   # allow traffic from anywhere
#   source                    = "0.0.0.0/0"
# }

resource "oci_core_internet_gateway" "microcloud-internet-gateway" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_virtual_network.microcloud-vnet.id

  display_name = "${local.prefix}-internet-gateway"
}

# resource "oci_core_default_route_table" "microcloud-route-table" {
#   manage_default_resource_id = oci_core_virtual_network.microcloud-vnet.default_security_list_id

#   display_name = "${local.prefix}-route-table"

#   route_rules {
#     network_entity_id = oci_core_internet_gateway.microcloud-internet-gateway.id

#     description = "Default route"
#     destination = "0.0.0.0/0"
#   }
# }

resource "oci_core_instance" "microcloud-vms" {
    count               = local.provider_config.quantity 
    availability_domain = local.chosen_availability_domain

    compartment_id      = oci_identity_compartment.tf-compartment.id
    shape               = local.selected_server_sizes[count.index].shape
    display_name        = "${local.prefix}-vm-${count.index}"
    preserve_boot_volume = try(local.provider_config.preserve_boot_volume, false)

    shape_config {
      memory_in_gbs = local.selected_server_sizes[count.index].memory_in_gbs
      ocpus         = local.selected_server_sizes[count.index].ocpus
    }

    source_details {
        source_type = "image"
        source_id   = local.selected_oci_core_images[count.index]
        boot_volume_size_in_gbs = try(local.provider_config.boot_volume_size_in_gbs, 50)
    #   source_id         = var.sou 
    }

    metadata = {
        ssh_authorized_keys = file(local.group_config.ansible_ssh_public_key_file)
    }

    agent_config {
        are_all_plugins_disabled = try(local.provider_config.are_all_plugins_disabled, true)
        is_management_disabled   = try(local.provider_config.is_management_disabled, true)
        is_monitoring_disabled   = try(local.provider_config.is_monitoring_disabled, true)
    }

    create_vnic_details {
        display_name   = "${local.prefix}-vnic-${count.index}"
        hostname_label = "${local.prefix}-vnic-${count.index}"
        # nsg_ids        = [oci_core_network_security_group.microcloud-nsg.id]
        subnet_id      = oci_core_subnet.microcloud-subnet.id
        assign_public_ip = try(local.provider_config.assign_public_ip, true) 
    }

    

    # lifecycle {
    #     ignore_changes = [source_details[0].source_id]
    # }

    # shape_config {
    #     ocpus = var.instance_ocpus
    #     memory_in_gbs = var.instance_shape_config_memory_in_gbs
    # }

}