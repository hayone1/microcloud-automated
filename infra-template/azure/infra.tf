resource "azurerm_resource_group" "rg" {
  name      = "microcloud-rg"
  location  = local.provider_config.region

  tags      = local.tags
}

resource "azurerm_virtual_network" "microcloud-vnet" {
  name                = "${local.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags      = local.tags
}

resource "azurerm_subnet" "microcloud-subnet" {
  name                  = "${local.prefix}-subnet"
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_name  = azurerm_virtual_network.microcloud-vnet.name
  address_prefixes      = ["10.0.0.0/16"]
}

resource "azurerm_public_ip" "public-ips" {
  count               = local.provider_config.quantity
  name                = "${local.prefix}-public-ip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags      = local.tags
}

resource "azurerm_network_interface" "interfaces" {
  count                 = local.provider_config.quantity
  name                  = "${local.prefix}-interface-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name

  ip_configuration {
    name                = "${local.prefix}-ipconfig-${count.index}"
    subnet_id           = azurerm_subnet.microcloud-subnet.id
    private_ip_address_allocation =  "Dynamic"
    public_ip_address_id = azurerm_public_ip.public-ips[count.index].id
  }

  tags      = local.tags
}

resource "azurerm_linux_virtual_machine" "microcloud-vms" {
  count                 = local.provider_config.quantity
  name                  = "${local.prefix}-vm-${count.index}"
  computer_name         = "${local.prefix}-vm-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.interfaces[count.index].id]
  size                  = local.selected_server_sizes[count.index]
  admin_username        =  local.server_user

  # delete_os_disk_on_termination = true
  # delete_data_disks_on_termination = true

  source_image_reference {
    publisher = local.provider_config.image.publisher
    offer = local.provider_config.image.offer
    sku = local.provider_config.image.sku
    version = local.provider_config.image.version
  }

  admin_ssh_key {
    username   = local.server_user
    public_key = file(local.group_config.ansible_ssh_public_key_file)
  }

  os_disk {
    caching              = var.storage-caching
    storage_account_type =  var.storage-account-type
  }

  provisioner "remote-exec" {
    inline = [ 
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
     ]

     connection {
       type     = "ssh"
       host     = self.public_ip_address
       user     = local.server_user
       private_key = file(local.group_config.ansible_ssh_private_key_file)
     }
  }

  tags          = local.tags
}

resource "azurerm_managed_disk" "local-volumes" {
  count                 = length(local.local_volume_map)
  name                  = "${local.prefix}localvolume${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  storage_account_type  = var.storage-account-type
  create_option         = "Empty"
  disk_size_gb          = local.local_volume_map[count.index]

  tags                  = local.tags
}
resource "azurerm_managed_disk" "ceph-volumes" {
  count                 = length(local.ceph_volume_map)
  name                  = "${local.prefix}cephvolume${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  storage_account_type  = var.storage-account-type
  create_option         = "Empty"
  disk_size_gb          = local.local_volume_map[count.index]

  tags                  = local.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "local-disks-attachment" {
  count                 = length(azurerm_managed_disk.local-volumes)
  virtual_machine_id    = azurerm_linux_virtual_machine.microcloud-vms[count.index].id
  managed_disk_id       = azurerm_managed_disk.local-volumes[count.index].id
  lun                   = (7 + count.index) #should be unique number
  caching               = var.storage-caching 
}
resource "azurerm_virtual_machine_data_disk_attachment" "ceph-disks-attachment" {
  count                 = length(azurerm_managed_disk.ceph-volumes)
  virtual_machine_id    = azurerm_linux_virtual_machine.microcloud-vms[count.index].id
  managed_disk_id       = azurerm_managed_disk.ceph-volumes[count.index].id
  lun                   = (27 + count.index) #should be unique number
  caching               = var.storage-caching 
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
