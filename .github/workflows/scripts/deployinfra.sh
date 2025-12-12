#!/usr/bin/env bash
set -euo pipefail

version="$1"
groupName="$2"

echo "Deploying in resource group '$groupName'"
az group create --name $groupName --location austriaeast --tag version=$version
az deployment group create \
--resource-group $groupName \
--template-file infra/infra.bicep \
--query "properties.outputs" \
--output json > outputs.json