# Azure Communication Mail Service

### Prerequisites

The Azure resource provider must be registered with the Microsoft.Communication namespace.

```bash
# Check if the provider is registered
az provider list --query "[?namespace=='Microsoft.Communication']" --output table

# Register the provider
az provider register --namespace Microsoft.Communication
```
