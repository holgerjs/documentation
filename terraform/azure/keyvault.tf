resource "azurerm_key_vault" "kv" {
  name                = "kv-bastion-test-001"
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  location            = azurerm_resource_group.rg.location
  sku_name            = "standard"

  purge_protection_enabled  = false
  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "ssh-key" {
  name         = "ubn-ssh-key"
  value        = tls_private_key.ubn_ssh.private_key_pem
  key_vault_id = azurerm_key_vault.kv.id
  tags = {
    vm = azurerm_linux_virtual_machine.vm_ubn_01.name
  }

  depends_on = [
    azurerm_role_assignment.kv_secrets_officer
  ]
}