param acrRg string
param acrName string

var appname = 'alido${resourceGroup().name}app'
var configname = 'alido${resourceGroup().name}config'
var kvname = 'alido${resourceGroup().name}kv'

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'alido${resourceGroup().name}sp'
  location: resourceGroup().location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true // this means linux
  }
}

resource app 'Microsoft.Web/sites@2025-03-01' = {
  name: appname
  location: resourceGroup().location
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|alidoplatformacr.azurecr.io/testapp:testversion' // this is refering to container registry
      acrUseManagedIdentityCreds: true // this means the web app should use system assigned identity for authentication. An AcrPull role is assigned automatically in ACR with this.
      appSettings: [
        {
          name: 'APP_CONFIG_ENDPOINT'
          value: appconfig.properties.endpoint
        }
        {
          name: 'KV_ENDPOINT'
          value: kv.properties.vaultUri
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource appconfig 'Microsoft.AppConfiguration/configurationStores@2025-06-01-preview' = {
  name: configname
  location: resourceGroup().location
  sku: {
    name: 'Developer'
  }
}

resource defaultConfig 'Microsoft.AppConfiguration/configurationStores/keyValues@2025-06-01-preview' = {
  parent: appconfig
  name: 'infra_default'
  properties: {
    value: 'infra_value'
    contentType: 'text/plain'
  }
}

resource configDataReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appconfig.id, app.id, 'datareader')
  scope: appconfig
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '516239f1-63e1-4d78-a4de-a74fb236a071'
    )
    principalId: app.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource kv 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: kvname
  location: resourceGroup().location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enablePurgeProtection: null // Purge protection is disabled to allow purging a vault as soon as it is deleted
  }
}

resource secretReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, app.id, 'secretreader')
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
    principalId: app.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module acrRbac './app-stack-rbac.bicep' = {
  name: 'acr-rbac22'
  scope: resourceGroup(acrRg) // the scope 
  params: {
    appId: app.id
    acrName: acrName
    principalId: app.identity.principalId
  }
}

output acrName string = acrName
output appServiceName string = app.name
output keyVaultName string = kvname
