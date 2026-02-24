#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="rg-bootstrap"
CONTAINER="tfstate"
LOCATION="austriaeast"

# Derive a deterministic unique suffix from the subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUFFIX=$(echo -n "$SUBSCRIPTION_ID" | md5sum | cut -c1-8)
STORAGE_ACCOUNT="sttfstate${SUFFIX}"

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cat > "$SCRIPT_DIR/backend.hcl" <<EOF
storage_account_name = "$STORAGE_ACCOUNT"
EOF

echo "Bootstrap complete. Storage account: $STORAGE_ACCOUNT"
