# hojingpt-infra
法人GPT's infrastructure managed by terraform.

# System Design Diagram
- https://drive.google.com/file/d/1nreqrtd-bwEGPyTbRpOivBrN-RqbMAwX/view?usp=sharing

# How to setup terraform

1. I would recommend installing [tfenv](https://github.com/tfutils/tfenv) instead of installing terraform. It is already versioned in `.terraform-version`.
1. Install [Azure CLI](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli)
1. Setup Azure CLI

    ```bash
    # login
    az login

    # list subscriptions
    az account list --output table

    # set subscription
    az account set --subscription "od-001-hojingpt"
    ```

# How to start new environment creation

- Create a resource group and set up a storage location for tfstate.

    ```bash
    # Naming policy: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
    ENV={dev|stage|prod}
    NAME=hojingpt
    RESOURCE_GROUP_NAME=rg-${NAME}-${ENV}
    STORAGE_ACCOUNT_NAME=st${NAME}terraform${ENV}
    CONTAINER_NAME=tfstate

    # Create resource group
    az group create --name $RESOURCE_GROUP_NAME --location japaneast

    # Create storage account
    az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob --allow-blob-public-access false

    # Create blob container
    az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME
    ```

# CI/CD

Unfortunately, CI/CD has not yet been set up. So, you need to use terraform locally.

# Exceptional manual managed resources

The following resources are manually configured.
- DNS
- Vault Key
- Container Apps

The following resources are partially configured manually.

### Azure Strage
- sthojingptterraform{dev|stage|prod}: Used for tfstate storage.

# NOTE
- [Azure Resource Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- List of [Azure regions](https://azure.microsoft.com/en-us/global-infrastructure/locations/)

   ```bash
   az account list-locations -o table
   ```

# How to deployo application

```bash
export ENV=stage
export NAME=ca-hojingpt-${ENV}-001
export IMAGE="crhojingptstage.azurecr.io/hojin-gpt:v5"

az containerapp up \
      --name ${NAME} \
      --resource-group rg-hojingpt-${ENV} \
      --location japaneast \
      --environment cae-hojingpt-${ENV}-001 \
      --image ${IMAGE} \
      --target-port 80 \
      --ingress external \
      --query properties.configuration.ingress.fqdn
      --env-vars 'PORT=80 staging=1'
```
