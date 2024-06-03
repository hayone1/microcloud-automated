resource "oci_identity_compartment" "tf-compartment" {
    compartment_id  = var.tenancy_ocid
    description     = "Compartment for Terraform resources."
    name            = "${local.prefix}-compartment"

    enable_delete   = true 
}

resource "oci_core_virtual_network" "microcloud-vnet" {
    display_name    = "${local.prefix}-vnet"
    compartment_id  = oci_identity_compartment.tf-compartment.id

    cidr_block     = try(local.provider_config.local_network_block, "10.0.0.0/16")
    dns_label       = "vnet"
}

resource "oci_core_security_list" "microcloud-security-list" {
    # manage_default_resource_id = oci_core_virtual_network.microcloud-vnet.default_security_list_id
    compartment_id  = oci_identity_compartment.tf-compartment.id
    vcn_id          = oci_core_virtual_network.microcloud-vnet.id
    display_name    = "${local.prefix}-nsg"
    # display_name    = "${local.prefix}-security-list"
    dynamic "ingress_security_rules" {
        for_each = local.allowed_ports
        iterator = port
        content {
            # protocol = local.protocol_numbers.tcp
            protocol = "all"
            source   = local.allowed_source_address_prefix

            # description = "SSH and HTTPS traffic from any origin"

            tcp_options {
                max = port.value
                min = port.value
            }
        }
    }

  egress_security_rules {
    destination = local.allowed_destination_address_prefix
    # protocol    = local.protocol_numbers.tcp
    protocol    = "all"

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
  # custom or same as vnet/vpc cidr/ip range
  cidr_block        = try(
    local.provider_config.local_subnet_block, 
    oci_core_virtual_network.microcloud-vnet.cidr_block
  )
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

    provisioner "remote-exec" {
    inline = [ 
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
      "echo 'Creating Server User...'",
      "adduser ${local.server_user}",
      "usermod -aG sudo ${local.server_user}"
      # # install nginx just for testing
      # "sudo apt update",
      # "sudo apt install -y nginx"
     ]

     connection {
       type     = "ssh"
       host     = self.public_ip
       # default user for oracle ubuntu images
       user     = "ubuntu"
       private_key = file(local.group_config.ansible_ssh_private_key_file)
      #  private_key = tls_private_key.global_key.private_key_pem
     }
  }

  freeform_tags = local.tags
    

    # lifecycle {
    #     ignore_changes = [source_details[0].source_id]
    # }

    # shape_config {
    #     ocpus = var.instance_ocpus
    #     memory_in_gbs = var.instance_shape_config_memory_in_gbs
    # }

}

# see https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/overview.htm
resource "oci_core_volume" "local-volumes" {
  count               = length(local.local_volume_map)
  compartment_id      = oci_identity_compartment.tf-compartment.id
  availability_domain = local.chosen_availability_domain
  display_name        = "${local.prefix}localvolume${count.index}"
  size_in_gbs         = local.local_volume_map[count.index]

  freeform_tags       = local.tags
}
resource "oci_core_volume" "ceph-volumes" {
  count               = length(local.ceph_volume_map)
  compartment_id      = oci_identity_compartment.tf-compartment.id
  availability_domain = local.chosen_availability_domain
  display_name        = "${local.prefix}cephvolume${count.index}"
  size_in_gbs         = local.ceph_volume_map[count.index]

  freeform_tags       = local.tags
}

resource "oci_core_volume_attachment" "local-disks-attachment" {
  count           = length(oci_core_volume.local-volumes)
  attachment_type = try(local.provider_config.attachment_type, "iSCSI")
  instance_id     = oci_core_instance.microcloud-vms[count.index].id
  volume_id       = oci_core_volume.local-volumes[count.index].id 

}

resource "ssh_resource" "hosts-data" {
  count       = length(oci_core_instance.microcloud-vms)
  host        = oci_core_instance.microcloud-vms[count.index].public_ip
  user        = local.server_user
  private_key = file(local.group_config.ansible_ssh_private_key_file)
  depends_on  = [ 
    digitalocean_volume_attachment.ceph-disks-attachment,
    digitalocean_volume_attachment.local-disks-attachment,
  ]
  when        = "create"
  commands    = [
    <<EOF
      local_volume_path=$(df | awk '{print $1, $6}' | grep ${try(digitalocean_volume.local-volumes[count.index].name, "_none")} | awk '{print $1}') &&
      ceph_volume_path=$(df | awk '{print $1, $6}' | grep ${try(digitalocean_volume.ceph-volumes[count.index].name, "_none")} | awk '{print $1}') &&
        index=$(echo -n ${digitalocean_droplet.microcloud-vms[count.index].name} | tail -c 1)  &&
        hostname=$(hostname) &&
        ipv4_address=$(hostname -I | awk '{print $1}') &&
        ipv4_address_iface=$(ip -o addr show | grep "inet $ipv4_address" | awk '{print $2}') &&
        ipv4_address_private='${digitalocean_droplet.microcloud-vms[count.index].ipv4_address_private}' &&
        ipv4_address_private_iface=$(ip -o addr show | grep "inet $ipv4_address_private" | awk '{print $2}') &&
        ipv4_address_private_cidr=$(ip -o addr show | grep "inet $ipv4_address_private" | awk '{print $4}') &&
        echo -e "hostname: $hostname\nipv4_address: $ipv4_address\nipv4_address_iface: $ipv4_address_iface\nipv4_address_private: $ipv4_address_private\nindex_key: $index\nlocal_volume_path: $local_volume_path\nceph_volume_path: $ceph_volume_path\nipv4_address_private_cidr: $ipv4_address_private_cidr\nipv4_address_private_iface: $ipv4_address_private_iface\n"
    EOF
  ]
}

output "ansible-hosts" {
  value = {
    # group the data by ipv4_address
    for data in [
      for host_data in ssh_resource.hosts-data :
        try(yamldecode(host_data.result), {})
    ] : data.ipv4_address => data

  }
}