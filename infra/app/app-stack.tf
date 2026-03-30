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

locals {
  workload = "cloudforge"
  suffix   = substr(md5(data.azurerm_subscription.current.id), 0, 5)
  tags = {
    workload    = local.workload
    environment = var.environment
    type        = "app"
    version     = var.ver
  }
}

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

resource "azurerm_resource_group" "app" {
  name     = "rg-${local.workload}-${var.environment}"
  location = "austriaeast"
  tags     = local.tags
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
    ASPNETCORE_ENVIRONMENT = var.environment == "stg" ? "Staging" : "Production"
    STORAGE_ACCOUNT = azurerm_storage_account.sa.name
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

resource "azurerm_storage_account" "sa" {
  name                     = "st${local.workload}${local.suffix}${var.environment}}"
  location                 = azurerm_resource_group.app.location
  tags                     = local.tags
  resource_group_name      = azurerm_resource_group.app.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_role_assignment" "sa_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

output "acr_name" {
  value = data.azurerm_container_registry.acr.name
}

output "app_service_name" {
  value = azurerm_linux_web_app.main.name
}
