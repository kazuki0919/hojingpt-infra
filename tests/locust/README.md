### About
Cloud Run にアプリをデプロイしてリクエストヘッダの情報を出力するためのテスト用アプリ

### deploy

```bash
gcloud config set project hojingpt-staging

gcloud builds submit --tag gcr.io/hojingpt-staging/yoda-test

gcloud run deploy yoda-test --image gcr.io/hojingpt-staging/yoda-test  \
  --project=hojingpt-staging --region=asia-northeast1 --memory=1024Mi --cpu=1 --timeout=300 \
  --allow-unauthenticated --ingress=all --port=8080 \
  --min-instances=0 --concurrency=100 --max-instances=20
```
