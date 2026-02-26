#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="rg-bootstrap"
CONTAINER="tfstate"
LOCATION="austriaeast"

# Derive a deterministic unique suffix from the subscription ID
echo "Fetching subscription ID..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUFFIX=$(echo -n "$SUBSCRIPTION_ID" | md5sum | cut -c1-8)
STORAGE_ACCOUNT="stbootstrap${SUFFIX}"
echo "Using storage account: $STORAGE_ACCOUNT"

# Create resource group if it doesn't exist
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
  echo "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION"
else
  echo "Resource group '$RESOURCE_GROUP' already exists, skipping."
fi

# Create storage account if it doesn't exist
if ! az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "Creating storage account '$STORAGE_ACCOUNT'..."
  az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --allow-blob-public-access false \
    --min-tls-version TLS1_2 \
    --tags type=terraform-backend
else
  echo "Storage account '$STORAGE_ACCOUNT' already exists, skipping."
fi

# Create blob container (idempotent)
echo "Creating blob container '$CONTAINER'..."
az storage container create \
  --name "$CONTAINER" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login

echo "Writing backend.hcl..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cat > "$SCRIPT_DIR/backend.hcl" <<EOF
storage_account_name = "$STORAGE_ACCOUNT"
EOF

echo "Bootstrap complete. Storage account: $STORAGE_ACCOUNT"
