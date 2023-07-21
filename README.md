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
    # if failed please try: az login --debug

    # list subscriptions
    az account list --output table

    # set subscription
    az account set --subscription "od-001-hojingpt"
    ```

1. Run

  ```bash
  cd azure/envs/dev
  tfenv install && terraform init
  terraform plan
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
- SSH Key
- Container Apps
    - Approval of private endpoint connections
    - Custom domain settings
    - ID
    - Scale and Replica
- Logic Apps

The following resources are partially configured manually.

### Azure Strage
- sthojingptterraform{dev|stage|prod}: Used for tfstate storage.

# NOTE
- [Azure Resource Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- List of [Azure regions](https://azure.microsoft.com/en-us/global-infrastructure/locations/)

   ```bash
   az account list-locations -o table
   ```
- [Azure Bastion](https://docs.google.com/document/d/1daoM0lFzi9ieJJr2nSPPZnY1SKvXmyTAb7t5YUEU5MY/edit)
- [Azure OpenAI RateLimit-1](https://givery.slack.com/archives/C04TPKW8J5A/p1684717457424859)
- [Azure OpenAI RateLimit-2](https://givery.slack.com/archives/C04U24W5EKU/p1685596618501169)

# Bastion

### SSH Key

Azure SSH keys are stored in the Key Vault.
Do not use this key for anything other than recovery, and normally register each SSH key with the server to connect.

```bash
export ENV=stage|prod

# Download
az keyvault secret download --vault-name kv-hojingpt-${ENV} --name ssh-hojingpt-${ENV}-001 --file "~/.ssh/ssh-hojingpt-${ENV}-001.pem"

# Upload: Note that pem files containing newline codes cannot be stored properly without cli.
az keyvault secret set --vault-name kv-hojingpt-${ENV} --name ssh-hojingpt-${ENV}-001 --file "~/.ssh/ssh-hojingpt-${ENV}-001.pem"
```

### How to connect

In the future, we plan to block access from IPs other than the Givery office IP. In this case, an office VPN will be required.

```bash
az login
az account list
az account set --subscription "2b7c69c8-29da-4322-a5fa-baae7454f6ef"

# Azure Bastion (SSH Key)
az network bastion ssh --name bastion-hojingpt-stage-001 \
  --resource-group rg-hojingpt-stage \
  --target-resource-id /subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-stage/providers/Microsoft.Compute/virtualMachines/vm-hojingpt-stage-bastion-001 \
  --auth-type ssh-key \
  --username azureuser \
  --ssh-key /Users/yyoda/.ssh/ssh-hojingpt-stage-001.pem

# Azure bastion (Azure Active Directory)
az network bastion ssh --name bastion-hojingpt-stage-001 \
  --resource-group rg-hojingpt-stage \
  --target-resource-id /subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-stage/providers/Microsoft.Compute/virtualMachines/vm-hojingpt-stage-bastion-001 \
  --auth-type AAD

az network bastion ssh --name bastion-hojingpt-prod-001 \
  --resource-group rg-hojingpt-prod \
  --target-resource-id /subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-prod/providers/Microsoft.Compute/virtualMachines/vm-hojingpt-prod-bastion-001 \
  --auth-type AAD

# SSH
# 1. tunnel
az network bastion tunnel --name bastion-hojingpt-stage-001 \
  --resource-group rg-hojingpt-stage --target-resource-id /subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-stage/providers/Microsoft.Compute/virtualMachines/vm-hojingpt-stage-bastion-001 \
  --resource-port 22 --port 5022

# 2. then, connect to localhost:5022
ssh -i ~/.ssh/ssh-hojingpt-stage-001.pem -p 5022 azureuser@127.0.0.1
```

# MySQL

### How to connect

The password is stored in the Vault Key as [mysql-hojingpt-stage-password-001](https://portal.azure.com/#@givery.onmicrosoft.com/asset/Microsoft_Azure_KeyVault/Secret/https://kv-hojingpt-stage.vault.azure.net/secrets/mysql-hojingpt-stage-password-001) and [mysql-hojingpt-prod-password-001](https://portal.azure.com/#@givery.onmicrosoft.com/asset/Microsoft_Azure_KeyVault/Secret/https://kv-hojingpt-prod.vault.azure.net/secrets/mysql-hojingpt-prod-password-001).

```bash
# staging
mysql -h mysql-hojingpt-stage-001.mysql.database.azure.com -u hojingpt -p

# production
mysql -h mysql-hojingpt-prod-001.mysql.database.azure.com -u hojingpt -p
```

# Redis

### How to connect

Azure requires authentication. After connecting, execute the AUTH command.
- [staging's ACCESS_KEY](https://portal.azure.com/#@givery.onmicrosoft.com/resource/subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-stage/providers/Microsoft.Cache/Redis/redis-hojingpt-stage-001/keys)
- [production's ACCESS_KEY](https://portal.azure.com/#@givery.onmicrosoft.com/resource/subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-prod/providers/Microsoft.Cache/Redis/redis-hojingpt-prod-001/keys)

```bash
# staging
redis-cli -h redis-hojingpt-stage-001.redis.cache.windows.net
AUTH "${ACCESS_KEY}"

# production
redis-cli -h redis-hojingpt-prod-001.redis.cache.windows.net
AUTH "${ACCESS_KEY}"
```

# Deployment

### Build and Deploy for staging

```bash
export IMAGE=hojingpt/app:v1.0

# build and push
az acr build --registry crhojingptstage --platform linux/amd64 --image ${IMAGE} .

# check if needed
# az acr login --name crhojingptstage
# docker pull crhojingptstage.azurecr.io/${IMAGE}

az containerapp up \
  --name ca-hojingpt-stage-001 \
  --resource-group rg-hojingpt-stage \
  --location japaneast \
  --environment cae-hojingpt-stage-001 \
  --image "crhojingptstage.azurecr.io/${IMAGE}" \
  --target-port 80 \
  --ingress external \
  --query properties.configuration.ingress.fqdn \
  --env-vars "PORT=80" "staging=1"
```

### Build and Deploy for production

```bash
export IMAGE=hojingpt/app:v0.2

# build and push
az acr build --registry crhojingptprod --platform linux/amd64 --image ${IMAGE} .

# check if needed
# az acr login --name crhojingptprod
# docker pull crhojingptprod.azurecr.io/${IMAGE}

az containerapp up \
  --name ca-hojingpt-prod-001 \
  --resource-group rg-hojingpt-prod \
  --location japaneast \
  --environment cae-hojingpt-prod-001 \
  --image "crhojingptprod.azurecr.io/${IMAGE}" \
  --target-port 80 \
  --ingress external \
  --query properties.configuration.ingress.fqdn \
  --env-vars "PORT=80" "prod=1"
```
