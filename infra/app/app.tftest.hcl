mock_provider "azurerm" {}

override_data {
  target = data.terraform_remote_state.platform
  values = {
    outputs = {
      acr_name = "crplatformabcdef"
    }
  }
}

override_data {
  target = data.azurerm_client_config.current
  values = {
    tenant_id = "00000000-0000-0000-0000-000000000000"
  }
}

override_data {
  target = data.azurerm_container_registry.acr
  values = {
    id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform/providers/Microsoft.ContainerRegistry/registries/crplatformabcdef"
    login_server = "crplatformabcdef.azurecr.io"
  }
}

variables {
  ver = "test"
}

run "resource_group" {
  command = plan

  variables {
    ver = "the-version"
  }

  assert {
    condition     = azurerm_resource_group.app.tags["version"] == var.ver
    error_message = "Resource group must be tagged with the infrastructure version"
  }
}

run "web_app" {
  command = plan

  assert {
    condition     = azurerm_linux_web_app.main.site_config.container_registry_use_managed_identity == true
    error_message = "Web App must access ACR via managed identity"
  }
}

run "key_vault" {
  command = plan

  assert {
    condition     = azurerm_key_vault.main.sku_name == "standard"
    error_message = "Key Vault SKU must be 'standard'"
  }

  assert {
    condition     = azurerm_key_vault.main.rbac_authorization_enabled == true
    error_message = "Key Vault RBAC must be enabled"
  }
}

run "app_config" {
  command = plan

  assert {
    condition     = azurerm_app_configuration.main.sku == "free"
    error_message = "App Configuration SKU must be 'free'"
  }
}
