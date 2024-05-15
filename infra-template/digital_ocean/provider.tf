terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    ssh = {
      source = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}

provider "digitalocean" {
  token = var.provider_token
}

provider "ssh" {}