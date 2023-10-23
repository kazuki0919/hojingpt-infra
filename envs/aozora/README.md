# Bastion

### SSH Key

Azure SSH keys are stored in the Key Vault.
Do not use this key for anything other than recovery, and normally register each SSH key with the server to connect.

```bash
export ENV=stage|prod

# Download
az keyvault secret download --vault-name kv-aozoragpt-${ENV} --name ssh-aozoragpt-${ENV}-001 --file "~/.ssh/ssh-aozoragpt-${ENV}-001.pem"

# Upload: Note that pem files containing newline codes cannot be stored properly without cli.
az keyvault secret set --vault-name kv-aozoragpt-${ENV} --name ssh-aozoragpt-${ENV}-001 --file "~/.ssh/ssh-aozoragpt-${ENV}-001.pem"
```

### How to connect

```bash
az login
az account list --output table
az account set --subscription "xgai-aozoragpt-001"

# Connect by Azure Bastion Service with Azure AD
az network bastion ssh --name bastion-aozoragpt-stage-001 \
  --resource-group rg-aozoragpt-stage \
  --target-resource-id /subscriptions/efed9001-dfc7-4111-bff2-2e643439ac84/resourceGroups/rg-aozoragpt-stage/providers/Microsoft.Compute/virtualMachines/vm-aozoragpt-stage-bastion-001 \
  --auth-type AAD

az network bastion ssh --name bastion-aozoragpt-prod-001 \
  --resource-group rg-aozoragpt-prod \
  --target-resource-id /subscriptions/efed9001-dfc7-4111-bff2-2e643439ac84/resourceGroups/rg-aozoragpt-prod/providers/Microsoft.Compute/virtualMachines/vm-aozoragpt-prod-bastion-001 \
  --auth-type AAD

# Connect by SSH tunnel
# 1. tunnel
az network bastion tunnel --name bastion-aozoragpt-stage-001 \
  --resource-group rg-aozoragpt-stage --target-resource-id /subscriptions/efed9001-dfc7-4111-bff2-2e643439ac84/resourceGroups/rg-aozoragpt-stage/providers/Microsoft.Compute/virtualMachines/vm-aozoragpt-stage-bastion-001 \
  --resource-port 22 --port 5022

az network bastion tunnel --name bastion-aozoragpt-prod-001 \
  --resource-group rg-aozoragpt-prod --target-resource-id /subscriptions/efed9001-dfc7-4111-bff2-2e643439ac84/resourceGroups/rg-aozoragpt-prod/providers/Microsoft.Compute/virtualMachines/vm-aozoragpt-prod-bastion-001 \
  --resource-port 22 --port 5022

# 2. then, connect to localhost:5022
ssh -i ~/.ssh/aozoragpt-yoda.pem -p 5022 azureuser@127.0.0.1

# 3. To add a new user to be allowed to connect via SSH tunneling, add the public key to /home/azureuser/.ssh/authorized_keys. This setting is not necessary for 'az network bastion ssh', but is required if you want to use SSH or SCP with 'az network bastion tunnel'
sudo -i
su azureuser
vim ~/.ssh/authorized_keys
```
