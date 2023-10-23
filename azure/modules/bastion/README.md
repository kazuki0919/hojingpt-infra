# Bastion Module

### Prerequisite

This module assumes that encryption is enabled on the host. Therefore, please execute the following commands beforehand.
see: https://learn.microsoft.com/ja-jp/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli#prerequisites

```bash
# Register EncryptionAtHost feature
az feature register --namespace Microsoft.Compute --name EncryptionAtHost

# Wait a min... and check status
az feature show --namespace Microsoft.Compute --name EncryptionAtHost
```
