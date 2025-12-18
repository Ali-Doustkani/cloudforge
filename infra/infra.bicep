var acrname = 'alido${resourceGroup().name}acr'
var appname = 'alido${resourceGroup().name}app'
var configname = 'alido${resourceGroup().name}config'

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'linux'
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
      linuxFxVersion: 'DOCKER|${acrname}.azurecr.io/testapp:testversion' // this is refering to container registry
      acrUseManagedIdentityCreds: true // this means the web app should use system assigned identity for authentication. An AcrPull role is assigned automatically in ACR with this.
      appSettings: [
        {
          name: 'APP_CONFIG_ENDPOINT'
          value: appconfig.properties.endpoint
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: acrname
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, app.id, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
    principalId: app.identity.principalId
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
  }
}

output acrName string = acrname
output appServiceName string = app.name
output appConfigName string = appconfig.name
output appConfigEndpoint string = appconfig.properties.endpoint
