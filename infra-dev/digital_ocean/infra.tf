# Temporary key pair used for SSH accesss
resource "digitalocean_ssh_key" "terraform_ssh" {
  name       = "${local.prefix}-droplet-ssh-key"
  # public_key = tls_private_key.global_key.public_key_openssh
  public_key = file(local.group_config.ansible_ssh_public_key_file)
}

resource "digitalocean_volume" "local-volume" {
  count                   = local.provider_config.quantity
  region                  = local.provider_config.region
  name                    = "${local.prefix}localvolume${count.index}"
  size                    = local.local_volume_map[count.index]
  initial_filesystem_type = "ext4"
  description             = "Volume to be used for microcloud storage."
}
resource "digitalocean_volume" "ceph-volume" {
  count                   = local.provider_config.quantity
  region                  = local.provider_config.region
  name                    = "${local.prefix}cephvolume${count.index}"
  size                    = local.ceph_volume_map[count.index]
  initial_filesystem_type = "ext4"
  description             = "Volume to be used for microcloud storage."
}


resource "digitalocean_droplet" "microcloud-droplet" {
  count       = local.provider_config.quantity
  image       = local.provider_config.os
  name        = "${local.prefix}-droplet-${count.index}"
  region      = local.provider_config.region
  size        = local.selected_server_size[count.index]
  ssh_keys    = [digitalocean_ssh_key.terraform_ssh.fingerprint]
  volume_ids  = [
    digitalocean_volume.local-volume[count.index].id,
    digitalocean_volume.ceph-volume[count.index].id
  ]
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