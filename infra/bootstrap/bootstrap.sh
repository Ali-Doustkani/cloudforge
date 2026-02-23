#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="tfstate-rg"
STORAGE_ACCOUNT="alidotfstate"
CONTAINER="tfstate"
LOCATION="austriaeast"

# Create resource group (idempotent)
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

# Create storage account if it doesn't exist
if ! az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --allow-blob-public-access false
fi

# Create blob container (idempotent)
az storage container create \
  --name "$CONTAINER" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login
