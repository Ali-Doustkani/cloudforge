terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "cftfstate"
    container_name       = "tfstate"
    key                  = "platform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

locals {
  suffix = substr(md5(data.azurerm_subscription.current.id), 0, 6)
}

variable "ver" {
  type = string
  description = "version of the infrastructure. git sha."
}

resource "azurerm_resource_group" "main" {
  name     = "rg-platform"
  location = "austriaeast"
  tags = {
    type    = "platform"
    version = var.ver
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "crplatform${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku = "Basic"
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}