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

# assign secret officer to pipeline service principal to set test secret
keyVaultName=$(jq --raw-output ".keyVaultName.value" outputs.json)
githubServicePrincipalObjId="2aa460f0-b63a-465d-8d73-a2662efc80e2"
echo "Assigning secret officer role of $keyVaultName to github service principal"
az role assignment create \
  --assignee-object-id "$githubServicePrincipalObjId" \
  --assignee-principal-type ServicePrincipal \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$groupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"

acrName=$(jq --raw-output ".acrName.value" outputs.json)
echo "Importing test image into registry '$acrName'"
az acr import --name $acrName --source ghcr.io/ali-doustkani/testapp:latest --image testapp:testversion

appServiceName=$(jq --raw-output ".appServiceName.value" outputs.json)
echo "Restarting app '$appServiceName'"
az webapp restart --name $appServiceName --resource-group $groupName

# set secret for testing
# it might take some time for the `role assignment create` to be applied
for i in {1..5}; do
  echo "Attempt $i: setting secret in $keyVaultName"
  if az keyvault secret set --name infra-default --value infra_value --vault-name "$keyVaultName"; then
    break
  fi
  sleep 10
done

# save into github variables
echo "url=https://$appServiceName.azurewebsites.net" >> $GITHUB_OUTPUT