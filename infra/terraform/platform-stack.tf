provider "azurerm" {
  features {}
}

variable "version" {
  type = string
  description = "version of the infrastructure. git sha."
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

resource "azurerm_resource_group" "main" {
  name     = "platform"
  location = "austriaeast"
  tags = {
    type    = "platform"
    version = var.version
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "alido${azurerm_resource_group.main.name}acr"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku = "Basic"
}
