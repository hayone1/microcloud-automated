# Temporary key pair used for SSH accesss
resource "digitalocean_ssh_key" "terraform_ssh" {
  name       = "${local.prefix}-droplet-ssh-key"
  # public_key = tls_private_key.global_key.public_key_openssh
  public_key = file(local.group_config.ansible_ssh_public_key_file)
}

resource "digitalocean_volume" "local-volume" {
  count                   = length(local.local_volume_map)
  region                  = local.provider_config.region
  name                    = "${local.prefix}localvolume${count.index}"
  size                    = local.local_volume_map[count.index]
  initial_filesystem_type = "ext4"
  description             = "Volume to be used for microcloud storage."
}
resource "digitalocean_volume" "ceph-volume" {
  count                     = length(local.ceph_volume_map)
  region                    = local.provider_config.region
  name                      = "${local.prefix}cephvolume${count.index}"
  size                      = local.ceph_volume_map[count.index]
  initial_filesystem_type   = "ext4"
  description               = "Volume to be used for microcloud storage."
}


resource "digitalocean_droplet" "microcloud-droplet" {
  count       = local.provider_config.quantity
  image       = local.provider_config.os
  name        = "${local.prefix}-droplet-${count.index}"
  region      = local.provider_config.region
  size        = local.selected_server_size[count.index]
  # private key
  ssh_keys    = [digitalocean_ssh_key.terraform_ssh.fingerprint]
  # set both local and ceph volume if created, or either of them or none
  volume_ids  = (
    length(digitalocean_volume.local-volume) > 0 && length(digitalocean_volume.ceph-volume) > 0 ?
      [
        digitalocean_volume.local-volume[count.index].id,
        digitalocean_volume.ceph-volume[count.index].id
      ]  : 
      length(digitalocean_volume.local-volume) > 0 ?
            [digitalocean_volume.local-volume[count.index].id] :
      length(digitalocean_volume.ceph-volume) > 0 ?
            [digitalocean_volume.ceph-volume[count.index].id] :
      []
  )
  
  # ssh_keys  = [digitalocean_ssh_key.terraform_ssh.fingerprint]

  provisioner "remote-exec" {
    inline = [ 
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'"
      # # install nginx just for testing
      # "sudo apt update",
      # "sudo apt install -y nginx"
     ]

     connection {
       type     = "ssh"
       host     = self.ipv4_address
       user     = local.server_user
       private_key = file(local.group_config.ansible_ssh_private_key_file)
      #  private_key = tls_private_key.global_key.private_key_pem
     }

     
  }
}

# get host data directly from host, this offers a generic way of doing do
# for any cloud provider
resource "ssh_resource" "hosts-data" {
  count       = length(digitalocean_droplet.microcloud-droplet)
  host        = digitalocean_droplet.microcloud-droplet[count.index].ipv4_address
  user        = local.server_user
  private_key = file(local.group_config.ansible_ssh_private_key_file)
  # agent       = true
  when        = "create"
  commands    = [
    <<EOF
      local_volume_path=$(df | awk '{print $1, $6}' | grep ${try(digitalocean_volume.local-volume[count.index].name, "_none")} | awk '{print $1}') &&
      ceph_volume_path=$(df | awk '{print $1, $6}' | grep ${try(digitalocean_volume.ceph-volume[count.index].name, "_none")} | awk '{print $1}') &&
        index=$(echo -n ${digitalocean_droplet.microcloud-droplet[count.index].name} | tail -c 1)  &&
        hostname=$(hostname) &&
        ipv4_address=$(hostname -I | awk '{print $1}') &&
        ipv4_address_private='${digitalocean_droplet.microcloud-droplet[count.index].ipv4_address_private}' &&
        private_interface='${digitalocean_droplet.microcloud-droplet[count.index].ipv4_address_private}' &&
        ipv4_address_private_cidr=$(ip -o addr show | grep "inet $ipv4_address_private" | awk '{print $4}') &&
        ipv4_address_private_iface=$(ip -o addr show | grep "inet $ipv4_address_private" | awk '{print $2}') &&
        echo -e "hostname: $hostname\nipv4_address: $ipv4_address\nipv4_address_private: $ipv4_address_private\nindex_key: $index\nlocal_volume_path: $local_volume_path\nceph_volume_path: $ceph_volume_path\nipv4_address_private_cidr: $ipv4_address_private_cidr\n"
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

# output "ansible-hosts" {
#   value = {
#     for volume_datum in out :
#       volume_datum.index_key => volume_datum
#   }
# }


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

#   # droplet_ids = [digitalocean_droplet.microcloud-droplet.*.id]
#   droplet_ids = [
#     for droplet in digitalocean_droplet.microcloud-droplet : droplet.id
#   ]
# }