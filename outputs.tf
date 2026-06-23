output "ip_address" {
  value = {
    for k, v in module.mythic : k => v.public_ip_address
  }
}
