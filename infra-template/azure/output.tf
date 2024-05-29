output "ansible-hosts" {
  value = {
    # group the data by ipv4_address
    for data in [
      for host_data in ssh_resource.hosts-data :
        try(yamldecode(host_data.result), {})
    ] : data.ipv4_address => data

  }
}