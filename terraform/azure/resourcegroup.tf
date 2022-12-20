resource "azurerm_resource_group" "rg" {
  location = "westeurope"
  name     = "bastion-test-rg"
  tags = {
    owner       = "me"
    environment = "test"
  }
}