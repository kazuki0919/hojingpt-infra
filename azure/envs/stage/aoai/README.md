
### Testing from the bastion host (stage)

```bash
export YOUR_RESOURCE_NAME="cog-hojingpt-stage-private-001"
export YOUR_API_KEY="xxxx"
export YOUR_DEPLOYMENT_NAME="model0001"

curl "https://$YOUR_RESOURCE_NAME.openai.azure.com/openai/deployments/$YOUR_DEPLOYMENT_NAME/chat/completions?api-version=2023-03-15-preview" \
  -H "Content-Type: application/json" \
  -H "api-key: $YOUR_API_KEY" \
  -d "{ \"messages\": [{\"role\":\"system\",\"content\":\"You are an AI assistant that helps people find information.\"},{\"role\":\"user\",\"content\":\"こんにちはを英語でいうと？\"}], \"max_tokens\": 800, \"temperature\": 0.7, \"frequency_penalty\": 0, \"presence_penalty\": 0,\"top_p\": 0.95, \"stop\": null }"
```
