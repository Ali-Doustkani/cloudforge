# Architecture
``` mermaid
flowchart LR
    subgraph rg[Resource Group: rg]
      AppServicePlan["`App Service Plan
      OS: Linux
      Tier: B1`"]
      AppService[App Service]
      ACR["`Azure Container Registry
      Tier: Basic`"]
      AppConfig[App Configuration]
    end 

    AppService --> AppServicePlan
    AppService -- uami --> ACR
    AppService -- uami --> AppConfig

```
# Testing
1. Infrastrcuture is installed with IaC with a pipeline
2. A default docker image is used for testing after infrastructure deployment.
3. todo: Accessibility of App Service to App Configuration is tested via ssh.

# Tooling
- Infrastructure Deployment: Bicep
- App Deployment: Github Actions


# Application Functionalities
Follow App Configuration Quick Start Guide

## App Configuration
- Read config from app config resource
- Refresh on app configuration value changes
- Support feature flags


# Learned
**To login into ACR and push an image:**
``` bash
az acr login -n myacr.azurecr.io
```

**To deploy your IaC into Azure:**
``` sh
az deployment group create -g rg --template-file ./infra/infra.bicep
```

**To integrate github with azure:**

Create a service principal in Entra:
``` sh
az ad sp create-for-rbac --name myspname
```

Add a federated credential to trust GitHub Actions:
``` sh
az ad app federated-credential create \
  --id <app-object-id> \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<org>/<repo>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

Add three secrets to GitHub (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`):
``` sh
az ad sp list --display-name myspname --query "[].appId" -o tsv  # AZURE_CLIENT_ID
az account show --query tenantId -o tsv                          # AZURE_TENANT_ID
az account show --query id -o tsv                                # AZURE_SUBSCRIPTION_ID
```

The service principal might not have enough permissions to do things (role assignments). You need to give it proper access for that.

**OAuth2.0 Access Token Response**
``` json
{
  "access_token": "...",  <- JWT token (header.payload.signature)
  "token_type": "Bearer", 
  "expires_on": "1765797550"
}
```

- `expires_on` is in written Unix Epoch timestamp form.

**SSH to App Service with Containers**

There are conventions defined by Microsoft you have to follow to allow `az webapp ssh` to work. 
