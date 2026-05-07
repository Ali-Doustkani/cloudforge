terraform {
  required_version = "~> 1.14"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.62"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.4"
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

provider "azuread" {}

data "azuread_service_principal" "github" {
  display_name = "github"
}

resource "azurerm_resource_group" "app" {
  name     = "rg-cloudforge"
  location = "austriaeast"
}

resource "azurerm_storage_account" "status" {
  name                     = "stcloudforgestatus"
  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_static_website" "static_web" {
  storage_account_id = azurerm_storage_account.status.id
  index_document     = "index.html"
  error_404_document = "error.html"
}

resource "azurerm_role_assignment" "github_actions_storage" {
  scope                = azurerm_storage_account.status.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.github.object_id
}
