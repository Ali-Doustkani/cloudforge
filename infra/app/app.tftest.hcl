mock_provider "azurerm" {}
mock_provider "azuread" {}

override_data {
  target = data.terraform_remote_state.platform
  values = {
    outputs = {
      acr_name            = "crplatformabcdef"
      resource_group_name = "rg-platform"
    }
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
  ver = "the-version"
  environment = "stg"
}

run "resource_group" {
  command = plan

  assert {
    condition     = azurerm_resource_group.app.tags["version"] == "the-version"
    error_message = "Resource group must be tagged with the infrastructure version"
  }

  assert {
    condition     = azurerm_resource_group.app.tags["type"] == "app"
    error_message = "Resrouce group must be of type 'app'"
  }

  assert {
    condition     = azurerm_resource_group.app.name == "rg-cloudforge-stg"
    error_message = "Resource group name must include the environment suffix"
  }
}

run "web_app" {
  command = plan

  assert {
    condition     = azurerm_linux_web_app.main.site_config[0].container_registry_use_managed_identity == true
    error_message = "Web App must access ACR via managed identity"
  }

  assert {
    condition     = azurerm_linux_web_app.main.app_settings["ASPNETCORE_ENVIRONMENT"] == "Staging"
    error_message = "ASPNETCORE_ENVIRONMENT must be 'Staging' for stg environment"
  }
}

run "web_app_prod_environment" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = azurerm_linux_web_app.main.app_settings["ASPNETCORE_ENVIRONMENT"] == "Production"
    error_message = "ASPNETCORE_ENVIRONMENT must be 'Production' for prod environment"
  }
}