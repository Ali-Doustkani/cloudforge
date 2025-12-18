#!/usr/bin/env bash
set -euo pipefail

groupName="$1"
bicepOutputPath="$2"

# read installed infra properties
acrName=$(jq --raw-output ".acrName.value" $bicepOutputPath)
appServiceName=$(jq --raw-output ".appServiceName.value" $bicepOutputPath)

echo "Importing test image into registry '$acrName'"
az acr import --name $acrName --source ghcr.io/ali-doustkani/testapp:latest --image testapp:testversion

echo "Restarting app '$appServiceName'"
az webapp restart --name $appServiceName --resource-group $groupName