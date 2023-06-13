# Staging environment

```bash
# Dump database
export PASS="OGUAg};sRE/79DPC"
export HOST=10.200.1.3
mysqldump -h ${HOST} -u root -p -B hojingpt -n \
  --quick --single-transaction \
  --add-drop-table --add-drop-trigger \
  --create-options \
  --disable-keys \
  --extended-insert \
  --set-charset \
  --triggers --routines --events \
  --add-locks \
  --lock-tables \
  --set-gtid-purged=OFF \
 > hojingpt.dump

# Download dump file
gcloud compute scp --recurse --zone=asia-northeast1-b hojingpt-bastion-staging:hojingpt.dump ~/Downloads/hojingpt.dump
hojingpt.dump

# Upload dump file
az network bastion tunnel --name bastion-hojingpt-stage-001 \
  --resource-group rg-hojingpt-stage --target-resource-id /subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-stage/providers/Microsoft.Compute/virtualMachines/vm-hojingpt-stage-bastion-001 \
  --resource-port 22 --port 5022

scp -i ~/.ssh/ssh-hojingpt-stage-001.pem -P 5022 hojingpt.dump azureuser@127.0.0.1:hojingpt.dump

# Connect to azure's bastion
ssh -i ~/.ssh/ssh-hojingpt-stage-001.pem -p 5022 azureuser@127.0.0.1

# Restore database
mysql -h mysql-hojingpt-stage-001.mysql.database.azure.com -u hojingpt -p < hojingpt.dump

# Count per tables
select table_name, table_rows from information_schema.TABLES where table_schema = 'hojingpt';
```




# Production environment

```bash
# Dump database
export PASS="~LNz(4fC+X^}L8T_"
export HOST=10.200.1.2
mysqldump -h ${HOST} -u root -p -B hojingpt -n \
  --quick --single-transaction \
  --add-drop-table --add-drop-trigger \
  --create-options \
  --disable-keys \
  --extended-insert \
  --set-charset \
  --triggers --routines --events \
  --set-gtid-purged=OFF \
> hojingpt.dump

# Download dump file
gcloud config set project hojingpt-prod
gcloud compute scp --recurse --zone=asia-northeast1-b hojingpt-bastion-prod:hojingpt.dump ~/Downloads/hojingpt.dump
hojingpt.dump

# Upload dump file
az network bastion tunnel --name bastion-hojingpt-prod-001 \
  --resource-group rg-hojingpt-prod --target-resource-id /subscriptions/2b7c69c8-29da-4322-a5fa-baae7454f6ef/resourceGroups/rg-hojingpt-prod/providers/Microsoft.Compute/virtualMachines/vm-hojingpt-prod-bastion-001 \
  --resource-port 22 --port 5022

scp -i ~/.ssh/ssh-hojingpt-prod-001.pem -P 5022 hojingpt.dump azureuser@127.0.0.1:hojingpt.dump

# Connect to azure's bastion
ssh -i ~/.ssh/ssh-hojingpt-prod-001.pem -p 5022 azureuser@127.0.0.1

# Restore database
mysql -h mysql-hojingpt-prod-001.mysql.database.azure.com -u hojingpt -p < hojingpt.dump

# Count per tables
select table_name, table_rows from information_schema.TABLES where table_schema = 'hojingpt';
```
