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
To login into ACR and push an image:
``` bash
az acr login -n myacr.azurecr.io
```

To deploy your IaC into Azure: 
``` sh
az deployment group create -g rg --template-file ./infra/infra.bicep
```