terraform {
  required_version = "~> 1.14"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.62"
    }
  }
  backend "azurerm" {
    resource_group_name = "rg-bootstrap"
    container_name      = "tfstate"
    key                 = "platform.tfstate"
    # storage_account_name is computed from the subscription ID and passed via -backend-config at init time
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

locals {
  workload = "cloudforge"
  suffix   = substr(md5(data.azurerm_subscription.current.id), 0, 6)
  tags = {
    workload = local.workload
    type     = "platform"
    version  = var.ver
  }
}

variable "ver" {
  type = string
  description = "version of the infrastructure. git sha."
}

resource "azurerm_resource_group" "main" {
  name     = "rg-platform"
  location = "austriaeast"
  tags     = local.tags
}

resource "azurerm_container_registry" "acr" {
  name                = "crplatform${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"
  tags                = local.tags
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
