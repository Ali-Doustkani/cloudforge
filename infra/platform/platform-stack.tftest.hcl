mock_provider "azurerm" {}

run "resource_group" {
  command = plan

  variables {
    ver = "my-version"
  }

  assert {
    condition     = azurerm_resource_group.main.tags["version"] == "my-version"
    error_message = "Resource group must be tagged with the infrastructure version"
  }

  assert {
    condition     = azurerm_resource_group.main.tags["type"] == "platform"
    error_message = "Resource group must have type of 'platform'"
  }
}
