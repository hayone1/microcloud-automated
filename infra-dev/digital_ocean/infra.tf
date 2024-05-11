# resource "tls_private_key" "global_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }
# resource "local_sensitive_file" "ssh_private_key_pem" {
#   filename        = "${path.module}/id_rsa"
#   content         = tls_private_key.global_key.private_key_pem
#   file_permission = "0600"
# }

# resource "local_file" "ssh_public_key_openssh" {
#   filename = "${path.module}/id_rsa.pub"
#   content  = tls_private_key.global_key.public_key_openssh
# }

# Temporary key pair used for SSH accesss
resource "digitalocean_ssh_key" "terraform_ssh" {
  name       = "${local.prefix}-droplet-ssh-key"
  # public_key = tls_private_key.global_key.public_key_openssh
  public_key = file(local.group_config.ansible_ssh_public_key_file)
}

resource "digitalocean_droplet" "microcloud-droplet" {
  count     = local.group_config.infra_providers[local.folder_name].quantity
  image     = local.group_config.infra_providers[local.folder_name].os
  name      = "${local.prefix}-droplet-${count.index}"
  region    = local.group_config.infra_providers[local.folder_name].region
  size      = "${local.selected_server_size}"
  ssh_keys  = [digitalocean_ssh_key.terraform_ssh.fingerprint]
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