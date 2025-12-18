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

acrName=$(jq --raw-output ".acrName.value" outputs.json)
echo "Importing test image into registry '$acrName'"
az acr import --name $acrName --source ghcr.io/ali-doustkani/testapp:latest --image testapp:testversion

appServiceName=$(jq --raw-output ".appServiceName.value" outputs.json)
echo "Restarting app '$appServiceName'"
az webapp restart --name $appServiceName --resource-group $groupName

# save into github variables
echo "url=https://{$appServiceName}.azurewebsites.net" >> $GITHUB_OUTPUT