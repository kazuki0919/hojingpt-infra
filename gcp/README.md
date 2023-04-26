# hojingpt-infra
法人GPT's infrastructure managed by terraform.

# System Design Diagram
- https://app.diagrams.net/#G1nreqrtd-bwEGPyTbRpOivBrN-RqbMAwX

# How to setup terraform

I would recommend installing [tfenv](https://github.com/tfutils/tfenv) instead of installing terraform.
It is already versioned in `.terraform-version`.

Here you will find the service account to use terraform.

- [staging env's service account](https://console.cloud.google.com/iam-admin/serviceaccounts/details/109141712245035595455?project=hojingpt-staging)
- [pdod env's service account](https://console.cloud.google.com/iam-admin/serviceaccounts/details/111437589679665217922?project=hojingpt-prod)

Then, The key for each service account is stored in Secret Manager.

- [staging env's service account json key](https://console.cloud.google.com/security/secret-manager/secret/service-account-terraform/versions?project=hojingpt-staging)
- [prod env's service account json key](https://console.cloud.google.com/security/secret-manager/secret/service-account-terraform/versions?project=hojingpt-prod)

The service account key was prepared for automation, but so far it has not been used.
To run terraform locally, please use gcloud

```bash
brew install --cask google-cloud-sdk
gcloud auth login
```

# CI/CD

Unfortunately, CI/CD has not yet been set up. So, you need to use terraform locally.

# Exceptional manual managed resources

### IAM Service Account
- `terraform`: A service account to run terraform locally or on CI.
- All others: Manual creation.

### Secret Manager
- `service-account-terraform`: Service account key for terraform.

### Cloud Strage
- `givery-hojingpt-tfstate-{staging|prod}`: Storage for terraform tfstate.

### Cloud Run (with Cloud Build and Container Registry)
- Basically, service deployment is done in `gcloud`.

### Container Registry
- Enable Vulnerability Scanning

### Enabling  API
- Basically, API activation is out of terraform's control.

### Cloud Monitoring Notification Channel
- Slack

### App Engine's setup
- Location is `asia-northeast1`
- Service Account is default
