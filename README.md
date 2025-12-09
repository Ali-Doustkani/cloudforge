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

You need to define a service principal in Entra for github. When you do that azure creates you a json authentication including a secret which you can use for your applications. Keep this secret in a safe place as you can't access it again. 
``` sh
az ad sp create-for-rbac --name myspname --json-auth
```
The content of this command can be saved in a secret called `AZURE_CREDENTIALS` in github secrets and be used.

This service principal might not have enough permissions to do things (role assignments). You need to give it proper access for that. 