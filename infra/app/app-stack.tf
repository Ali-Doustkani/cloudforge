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
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "app" {
  name     = "rg-cloudforge"
  location = "austriaeast"
}
