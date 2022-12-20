output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "tls_private_key" {
  value     = tls_private_key.ubn_ssh.private_key_pem
  sensitive = true
}

output "bastion_public_ip" {
  value = azurerm_public_ip.bastion_pip.ip_address
}