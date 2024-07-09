# Temporary key pair used for SSH accesss
resource "digitalocean_vpc" "microcloud-vpc" {
  name      = "${local.prefix}-vnet"
  region    = local.provider_config.region
  ip_range  = try(local.provider_config.local_network_block, "10.0.0.0/16")
}

resource "digitalocean_tag" "tags" {
  for_each = local.tags
  name = each.value
}

resource "digitalocean_ssh_key" "terraform_ssh" {
  name       = "${local.prefix}-vm-ssh-key"
  # public_key = tls_private_key.global_key.public_key_openssh
  public_key = file(local.group_config.ansible_ssh_public_key_file)
}

resource "digitalocean_droplet" "microcloud-vms" {
  count       = local.provider_config.quantity
  image       = local.provider_config.image.sku
  name        = "${local.prefix}-vm-${count.index}"
  region      = local.provider_config.region
  size        = local.selected_server_sizes[count.index]
  vpc_uuid    = digitalocean_vpc.microcloud-vpc.id
  ssh_keys    = [digitalocean_ssh_key.terraform_ssh.fingerprint]


  tags = [for tag in digitalocean_tag.tags : tag.id]
  
  # ssh_keys  = [digitalocean_ssh_key.terraform_ssh.fingerprint]

  provisioner "remote-exec" {
    inline = [ 
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
      "echo 'Creating Passwordless Sudo User...'",
      "useradd -U ${local.server_user}",
      "usermod -aG sudo ${local.server_user}",
      "echo '${local.server_user} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/${local.server_user}",
      "mkdir -p /home/${local.server_user}/.ssh",
      "cat ~/.ssh/authorized_keys >> /home/${local.server_user}/.ssh/authorized_keys",
      "echo user ${local.server_user} added successfully."
     ]

     connection {
       type     = "ssh"
       host     = self.ipv4_address
       user     = "root"
       private_key = file(local.group_config.ansible_ssh_private_key_file)
     }
  }
}

resource "digitalocean_volume" "local-volumes" {
  count                   = length(local.local_volume_map)
  name                    = "${local.prefix}localvolume${count.index}"
  region                  = local.provider_config.region
  size                    = local.local_volume_map[count.index]
  initial_filesystem_type = local.initial_filesystem_type
  description             = "Volume to be used for microcloud storage."
  tags = [for tag in digitalocean_tag.tags : tag.id]
}
resource "digitalocean_volume" "ceph-volumes" {
  count                     = length(local.ceph_volume_map)
  name                      = "${local.prefix}cephvolume${count.index}"
  region                    = local.provider_config.region
  size                      = local.ceph_volume_map[count.index]
  initial_filesystem_type   = local.initial_filesystem_type
  description               = "Volume to be used for microcloud storage."
  tags = [for tag in digitalocean_tag.tags : tag.id]
}

resource "digitalocean_volume_attachment" "local-disks-attachment" {
  count      = length(digitalocean_volume.local-volumes)
  droplet_id = digitalocean_droplet.microcloud-vms[count.index].id
  volume_id  = digitalocean_volume.local-volumes[count.index].id
}
resource "digitalocean_volume_attachment" "ceph-disks-attachment" {
  count      = length(digitalocean_volume.ceph-volumes)
  droplet_id = digitalocean_droplet.microcloud-vms[count.index].id
  volume_id  = digitalocean_volume.ceph-volumes[count.index].id
}

# get host data directly from host, this offers a generic way of doing do
# for any cloud provider
resource "ssh_resource" "hosts-data" {
  count       = length(digitalocean_droplet.microcloud-vms)
  host        = digitalocean_droplet.microcloud-vms[count.index].ipv4_address
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
      ceph_volume_paths=$(df | awk '{print $1, $6}' | grep ${try(digitalocean_volume.ceph-volumes[count.index].name, "_none")} | awk '{print $1}') &&
      index=$(echo -n ${digitalocean_droplet.microcloud-vms[count.index].name} | tail -c 1)  &&
      provider='digital_ocean' &&
      hostname=$(hostname) &&
      ipv4_address=$(hostname -I | awk '{print $1}') &&
      ipv4_address_iface=$(ip -o addr show | grep "inet $ipv4_address" | awk '{print $2}') &&
      ipv4_address_private='${digitalocean_droplet.microcloud-vms[count.index].ipv4_address_private}' &&
      ipv4_address_private_iface=$(ip -o addr show | grep "inet $ipv4_address_private" | awk '{print $2}') &&
      ipv4_address_private_cidr=$(ip -o addr show | grep "inet $ipv4_address_private" | awk '{print $4}') &&
      echo -e "provider: $provider\nhostname: $hostname\nipv4_address: $ipv4_address\nipv4_address_iface: $ipv4_address_iface\nipv4_address_private: $ipv4_address_private\nindex_key: $index\nlocal_volume_path: $local_volume_path\nceph_volume_paths: $ceph_volume_paths\nipv4_address_private_cidr: $ipv4_address_private_cidr\nipv4_address_private_iface: $ipv4_address_private_iface\n"
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

# resource "digitalocean_loadbalancer" "microcloud_lb" {
#   name    = "${local.prefix}-lb"
#   region  = local.group_config[local.folder_name].digital_ocean_region

#   forwarding_rule {
#     entry_port          = 80
#     entry_protocol  = "http"

#     target_port         = 80
#     target_protocol  = "http" 
#   }

#   healthcheck {
#     port      = 22
#     protocol  = "tcp"
#   }

#   # droplet_ids = [digitalocean_droplet.microcloud-vm.*.id]
#   droplet_ids = [
#     for droplet in digitalocean_droplet.microcloud-vm : droplet.id
#   ]
# }