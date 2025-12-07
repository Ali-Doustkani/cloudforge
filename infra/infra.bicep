var acrname = 'alidoacr'

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
  name: 'alidoapp1'
  location: resourceGroup().location
  properties: {
    serverFarmId: plan.id
    siteConfig:{
      linuxFxVersion: 'DOCKER|${acrname}.azurecr.io/nginx:latest' // this is refering to container registry
      acrUseManagedIdentityCreds: true // this means the web app should use system assigned identity for authentication. An AcrPull role is assigned automatically in ACR with this.
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: acrname
  location: resourceGroup().location
  sku:{
    name: 'Basic'
  }
}
