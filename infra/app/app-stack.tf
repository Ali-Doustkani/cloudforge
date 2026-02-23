terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "alidotfstate"
    container_name       = "tfstate"
    key                  = "app.tfstate"
  }
}

provider "azurerm" {
  features {}
}

variable "ver" {
  type        = string
  description = "version of the infrastructure. git sha."
}

variable "group_name" {
  type        = string
  description = "Resource group name (e.g. rg)"
}

locals {
  sp_name             = "alido${var.group_name}sp"
  app_name            = "alido${var.group_name}app"
  config_name         = "alido${var.group_name}config"
  kv_name             = "alido${var.group_name}kv"
  acr_rg              = "platform"
  acr_name            = "alidoplatformacr"
  github_sp_object_id = "2aa460f0-b63a-465d-8d73-a2662efc80e2"
}

data "azurerm_client_config" "current" {}

data "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = local.acr_rg
}

resource "azurerm_resource_group" "app" {
  name     = var.group_name
  location = "austriaeast"
  tags = {
    type    = "app"
    version = var.ver
  }
}

resource "azurerm_service_plan" "main" {
  name                = local.sp_name
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "main" {
  name                = local.app_name
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  service_plan_id     = azurerm_service_plan.main.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    container_registry_use_managed_identity = true
    application_stack {
      docker_image_name   = "testapp:testversion"
      docker_registry_url = "https://${data.azurerm_container_registry.acr.login_server}"
    }
  }

  app_settings = {
    APP_CONFIG_ENDPOINT = azurerm_app_configuration.main.endpoint
    KV_ENDPOINT         = azurerm_key_vault.main.vault_uri
  }
}

resource "azurerm_app_configuration" "main" {
  name                = local.config_name
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  sku                 = "free"
}

resource "azurerm_key_vault" "main" {
  name                       = local.kv_name
  location                   = azurerm_resource_group.app.location
  resource_group_name        = azurerm_resource_group.app.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "app_config_reader" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = local.github_sp_object_id
}

resource "azurerm_role_assignment" "app_config_data_owner" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = local.github_sp_object_id
}

output "acr_name" {
  value = data.azurerm_container_registry.acr.name
}

output "app_service_name" {
  value = azurerm_linux_web_app.main.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "app_config_name" {
  value = azurerm_app_configuration.main.name
}
