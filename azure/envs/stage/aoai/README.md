
### Testing from the bastion host (stage)

```bash
curl "https://oai-hojingpt-stage-private-001.openai.azure.com/openai/deployments/gpt35turbo0301001/completions?api-version=2022-12-01" \
  -H "Content-Type: application/json" \
  -H "api-key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -d '{
  "prompt": "<|im_start|>system\n関西弁で回答してください\n<|im_end|>\n<|im_start|>user\n元気ですか？\n<|im_end|>\n<|im_start|>assistant",
  "max_tokens": 800,
  "stop": ["<|im_end|>"]
}' | jq
```
