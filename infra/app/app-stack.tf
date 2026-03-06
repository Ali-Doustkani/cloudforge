terraform {
  required_version = "~> 1.14"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.62"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name = "rg-bootstrap"
    container_name      = "tfstate"
  }
}

provider "azurerm" {
  features {}
}

variable "ver" {
  type        = string
  description = "version of the infrastructure. git sha."
}

variable "environment" {
  type        = string
  description = "deployment environment. allowed values: stg, prod."
  validation {
    condition     = contains(["stg", "prod"], var.environment)
    error_message = "environment must be 'stg' or 'prod'."
  }
}

variable "github_sp_client_id" {
  type        = string
  description = "client_id of the SP used for role assignment"
}

locals {
  workload            = "cloudforge"
  suffix              = substr(md5(data.azurerm_subscription.current.id), 0, 6)
  kv_suffix           = substr(md5(data.azurerm_subscription.current.id), 0, 5)
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-bootstrap"
    storage_account_name = "stbootstrap${substr(md5(data.azurerm_subscription.current.subscription_id), 0, 8)}"
    container_name       = "tfstate"
    key                  = "platform.tfstate"
  }
}

data "azurerm_container_registry" "acr" {
  name                = data.terraform_remote_state.platform.outputs.acr_name
  resource_group_name = data.terraform_remote_state.platform.outputs.resource_group_name
}

data "azuread_service_principal" "github" {
  client_id = var.github_sp_client_id
}

resource "azurerm_resource_group" "app" {
  name     = "rg-${local.workload}-${var.environment}"
  location = "austriaeast"
  tags = {
    type    = "app"
    version = var.ver
  }
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${local.workload}-${var.environment}"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-${local.workload}-${var.environment}"
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
  name                = "appcs-${local.workload}-${var.environment}"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  sku                 = "free"
}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${local.workload}-${var.environment}-${local.kv_suffix}"
  location                   = azurerm_resource_group.app.location
  resource_group_name        = azurerm_resource_group.app.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
}

# resource "azurerm_cosmosdb_account" "db" {
#   name                          = "cosmos-${local.workload}-${var.environment}"
#   location                      = azurerm_resource_group.app.location
#   resource_group_name           = azurerm_resource_group.app.name
#   free_tier_enabled             = true
#   offer_type                    = "Standard"
#   local_authentication_disabled = true
#   consistency_policy {
#     consistency_level = "Session"
#   }
#   geo_location {
#     location          = azurerm_resource_group.app.location
#     failover_priority = 0
#   }
# }

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
  principal_id         = data.azuread_service_principal.github.object_id
}

resource "azurerm_role_assignment" "app_config_data_owner" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azuread_service_principal.github.object_id
}

# resource "azurerm_cosmosdb_sql_role_assignment" "db_contributor" {
#   resource_group_name = azurerm_resource_group.app.name
#   account_name        = azurerm_cosmosdb_account.db.name
#   role_definition_id  = "${azurerm_cosmosdb_account.db.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
#   principal_id        = azurerm_linux_web_app.main.identity[0].principal_id
#   scope               = azurerm_cosmosdb_account.db.id
# }

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
