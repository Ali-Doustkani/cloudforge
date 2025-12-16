#!/usr/bin/env bash
set -euo pipefail

groupName="$1"
bicepOutputPath="$2"

# read installed infra properties
acrName=$(jq --raw-output ".acrName.value" $bicepOutputPath)
appServiceName=$(jq --raw-output ".appServiceName.value" $bicepOutputPath)
url="https://${appServiceName}.azurewebsites.net"
echo "Testing app '$url'"

echo "Importing test image into registry '$acrName'"
az acr import --name $acrName --source docker.io/library/alidoustkani/testversion:6 --image nginx:testversion

echo "Restarting app '$appServiceName'"
az webapp restart --name $appServiceName --resource-group $groupName

timeout=100 #timeout in seconds
httpcode=$(curl --connect-timeout $timeout -i $url | head -n 1)
if [[ "$httpcode" == *"200 OK"* ]]; then
echo "PASSED -- 200OK"
else 
echo "Expected 200OK but received $httpcode"
exit 1
fi
welcome=$(curl --connect-timeout $timeout $url | grep "HTTP OK")
if [[ -z "$welcome" ]]; then
echo "Expected website content"
exit 1
fi