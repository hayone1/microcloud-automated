resource "alicloud_vpc" "microcloud-vpc" {
  vpc_name   = "${local.prefix}-vnet"
  cidr_block = try(local.provider_config.local_network_block, "10.0.0.0/16")

  tags      = local.tags
}

resource "alicloud_vswitch" "microcloud-vswitch" {
  vswitch_name  = "${local.prefix}-subnet"
  vpc_id        = alicloud_vpc.microcloud-vpc.id
  cidr_block    = try(
    local.provider_config.local_subnet_block, 
    alicloud_vpc.microcloud-vpc.cidr_block
  )
  zone_id    = local.chosen_availability_zone # should 0 be hardcoded?
}

resource "alicloud_security_group" "microcloud-nsg" {
  name    = "${local.prefix}-nsg"
  vpc_id  = alicloud_vpc.microcloud-vpc.id
}

resource "alicloud_security_group_rule" "microcloud-sr" {
  type              = "ingress" 
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 10
  security_group_id = alicloud_security_group.microcloud-nsg.id
  cidr_ip           = local.allowed_source_address_prefix
}

resource "alicloud_ecs_network_interface" "interfaces" {
  count                   = local.provider_config.quantity
  network_interface_name  = "${local.prefix}-interface-${count.index}"
  vswitch_id              = alicloud_vswitch.microcloud-vswitch.id
  security_group_ids      = [alicloud_security_group.microcloud-nsg.id]

  tags      = local.tags
}

resource "alicloud_instance" "microcloud-vms" {
  count                      = local.provider_config.quantity
  image_id                   = data.alicloud_images.available-images.images[0].id
  instance_type              = local.selected_server_sizes[count.index]
  instance_name              = "${local.prefix}-vm-${count.index}"
  host_name                  = "${local.prefix}-vm-${count.index}"
  security_groups            = [alicloud_security_group.microcloud-nsg.id]
  internet_charge_type       = local.internet_charge_type
  internet_max_bandwidth_out = local.internet_max_bandwidth_out # will allow public ip
  availability_zone          = local.chosen_availability_zone
  instance_charge_type       = local.instance_charge_type
  system_disk_category       = local.system_disk_category
  vswitch_id                 = alicloud_vswitch.microcloud-vswitch.id

  password                   = var.ANSIBLE_SSH_PASS 
  stopped_mode               = "StopCharging" 
  tags                       = local.tags 
}


resource "alicloud_ecs_disk" "local-volumes" {
  count               = length(local.local_volume_map)
  disk_name           = "${local.prefix}localvolume${count.index}"
  zone_id             = local.chosen_availability_zone
  category            = local.system_disk_category
  size                = local.local_volume_map[count.index]


  delete_auto_snapshot = local.delete_auto_snapshot
  enable_auto_snapshot = local.enable_auto_snapshot
  encrypted            = local.encrypted
  tags = local.tags
}
resource "alicloud_ecs_disk" "ceph-volumes" {
  count               = length(local.local_volume_map)
  disk_name           = "${local.prefix}cephvolume${count.index}"
  zone_id             = local.chosen_availability_zone
  category            = local.system_disk_category
  size                = local.ceph_volume_map[count.index]


  delete_auto_snapshot = local.delete_auto_snapshot
  enable_auto_snapshot = local.enable_auto_snapshot
  encrypted            = local.encrypted
  tags = local.tags
}

resource "alicloud_ecs_disk_attachment" "local-disks-attachment" {
  count       = length(alicloud_ecs_disk.local-volumes)
  disk_id     = alicloud_ecs_disk.local-volumes[count.index].id
  instance_id = alicloud_instance.microcloud-vms[count.index].id
}
resource "alicloud_ecs_disk_attachment" "ceph-disks-attachment" {
  count       = length(alicloud_ecs_disk.ceph-volumes)
  disk_id     = alicloud_ecs_disk.ceph-volumes[count.index].id
  instance_id = alicloud_instance.microcloud-vms[count.index].id
}

# ToDO
resource "ssh_resource" "hosts-data" {
  count       = length(azurerm_linux_virtual_machine.microcloud-vms)
  host        = azurerm_linux_virtual_machine.microcloud-vms[count.index].public_ip_address
  user        = local.server_user
  private_key = file(local.group_config.ansible_ssh_private_key_file)
  depends_on  = [ 
    azurerm_virtual_machine_data_disk_attachment.ceph-disks-attachment,
    azurerm_virtual_machine_data_disk_attachment.local-disks-attachment
  ]
  when        = "create"
  commands    = [
    <<EOF
      local_volume_path=$(lsscsi --scsi | awk '{print $1, $7}' | grep :${try(azurerm_virtual_machine_data_disk_attachment.local-disks-attachment[count.index].lun, "_none")}] | awk '{print $2}') &&
      ceph_volume_path=$(lsscsi --scsi | awk '{print $1, $7}' | grep :${try(azurerm_virtual_machine_data_disk_attachment.ceph-disks-attachment[count.index].lun, "_none")}] | awk '{print $2}') &&
        index=$(echo -n ${azurerm_linux_virtual_machine.microcloud-vms[count.index].name} | tail -c 1)  &&
        hostname=$(hostname) &&
        # ipv4_address=$(hostname -I | awk '{print $1}') &&
        ipv4_address=$(curl 'ip.me.uk') &&
        ipv4_address_iface=$(ip -o addr show | grep "inet $ipv4_address" | awk '{print $2}') &&
        ipv4_address_private='${azurerm_linux_virtual_machine.microcloud-vms[count.index].private_ip_address}' &&
        ipv4_address_private_iface=$(ip -o addr show | grep "inet $ipv4_address_private" | awk '{print $2}') &&
        ipv4_address_private_cidr=$(ip -o addr show | grep "inet $ipv4_address_private" | awk '{print $4}') &&
        ipv4_address_iface=$(ip -o addr show | grep "inet $ipv4_address_private" | awk '{print $2}') &&
        echo -e "hostname: $hostname\nipv4_address: $ipv4_address\nipv4_address_iface: $ipv4_address_iface\nipv4_address_private: $ipv4_address_private\nindex_key: $index\nlocal_volume_path: $local_volume_path\nceph_volume_path: $ceph_volume_path\nipv4_address_private_cidr: $ipv4_address_private_cidr\nipv4_address_private_iface: $ipv4_address_private_iface\n"
    EOF
  ]
}
