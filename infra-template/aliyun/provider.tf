terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = "~> 1.223.2"
    }
    ssh = {
      source = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}

provider "alicloud" {}

provider "ssh" {}