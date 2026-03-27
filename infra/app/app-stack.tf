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
  workload  = "cloudforge"
  kv_suffix = substr(md5(data.azurerm_subscription.current.id), 0, 5)
  tags = {
    workload    = local.workload
    environment = var.environment
    type        = "app"
    version     = var.ver
  }
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
  tags     = local.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.workload}-${var.environment}"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "app_service" {
  name                 = "snet-appservice"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "app-service-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-privateendpoints"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${local.workload}-${var.environment}"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = local.tags
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

  # docker_image_name is managed out-of-band by the deploy pipeline
  # Terraform provisions the resource but does not own the image tag at runtime.
  lifecycle {
    ignore_changes = [site_config[0].application_stack]
  }

  app_settings = {
    APP_CONFIG_ENDPOINT    = azurerm_app_configuration.main.endpoint
    KV_ENDPOINT            = azurerm_key_vault.main.vault_uri
    ASPNETCORE_ENVIRONMENT = var.environment == "stg" ? "Staging" : "Production"
    WEBSITE_DNS_SERVER     = "168.63.129.16"
  }

  tags = local.tags
}

resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_linux_web_app.main.id
  subnet_id      = azurerm_subnet.app_service.id
}

resource "azurerm_app_configuration" "main" {
  name                       = "appcs-${local.workload}-${var.environment}"
  location                   = azurerm_resource_group.app.location
  resource_group_name        = azurerm_resource_group.app.name
  sku                        = "standard"
  local_auth_enabled         = false
  public_network_access      = "Disabled"
  tags                       = local.tags
}

resource "azurerm_private_endpoint" "app_config" {
  name                = "pe-appcs-${local.workload}-${var.environment}"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-appcs-${local.workload}-${var.environment}"
    private_connection_resource_id = azurerm_app_configuration.main.id
    subresource_names              = ["configurationStores"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "appcs-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.app_config.id]
  }

  tags = local.tags
}

resource "azurerm_private_dns_zone" "app_config" {
  name                = "privatelink.azconfig.io"
  resource_group_name = azurerm_resource_group.app.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_config" {
  name                  = "vnetlink-appcs-${local.workload}-${var.environment}"
  resource_group_name   = azurerm_resource_group.app.name
  private_dns_zone_name = azurerm_private_dns_zone.app_config.name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = local.tags
}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${local.workload}-${var.environment}-${local.kv_suffix}"
  location                   = azurerm_resource_group.app.location
  resource_group_name        = azurerm_resource_group.app.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  tags                       = local.tags
}

resource "azurerm_key_vault_secret" "app_secret" {
  name         = "app-secret"
  value        = "hello-from-key-vault"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
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
  principal_id         = data.azuread_service_principal.github.object_id
}

resource "azurerm_role_assignment" "app_config_data_owner" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azuread_service_principal.github.object_id
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
