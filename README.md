# hojingpt-infra
法人GPT's infrastructure managed by terraform.

# How to setup terraform

I would recommend installing [tfenv](https://github.com/tfutils/tfenv) instead of installing terraform.
It is already versioned in `.terraform-version`.

Here you will find the service account to use terraform.

- [staging env's service account](https://console.cloud.google.com/iam-admin/serviceaccounts/details/109141712245035595455?project=hojingpt-staging)
- [pdod env's service account](https://console.cloud.google.com/iam-admin/serviceaccounts/details/111437589679665217922?project=hojingpt-prod)

Then, The key for each service account is stored in Secret Manager.

- [staging env's service account json key](https://console.cloud.google.com/security/secret-manager/secret/service-account-terraform/versions?project=hojingpt-staging)
- [prod env's service account json key](https://console.cloud.google.com/security/secret-manager/secret/service-account-terraform/versions?project=hojingpt-prod)

To run terraform locally, first download and store this secret key.
Then, set the following environment variables so that the service account key is recognized

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/Users/yyoda/.gcp/service_accounts/hojingpt/hojingpt-xxxx.json"
```

This completes the configuration, though, If you switch environments and run terraform, you will need to modify the environment variables as well, so it is recommended to use a tool such as [direnv](https://github.com/direnv/direnv).

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
