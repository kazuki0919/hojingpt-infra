# CAUTION

1. セマンティック検索は手動で有効化する必要があるので注意。ステージング環境は無料版、本番環境は有料版とする。

1. terraform でパブリックアクセスを無効にしてプライベートエンドポイントを作成すると、何故か Private DNS 名前が失敗し接続できない問題がある。
暫定処置として手動でリソース作成後、terraform import で sync するか、Cognitive Service を作成してから Private Endpoint を作成するようにする。

  ```bash
  $ nslookup srch-hojingpt-prod-001mc.search.windows.net
  Server:         127.0.0.53
  Address:        127.0.0.53#53

  Non-authoritative answer:
  srch-hojingpt-prod-001mc.search.windows.net     canonical name = srch-hojingpt-prod-001mc.privatelink.search.windows.net.
  srch-hojingpt-prod-001mc.privatelink.search.windows.net canonical name = azswjyj.japaneast.cloudapp.azure.com.
  Name:   azswjyj.japaneast.cloudapp.azure.com
  Address: 40.81.220.39 -> これはグローバルIPアドレス。プライベートエンドポイントのIPアドレスではない。
  ```

# NOTE
接続確認用 curl コマンドサンプル

```bash
curl -IL -X GET -H "Content-Type:application/json" -H "api-key:xxxx" "https://srch-hojingpt-stage-001.search.windows.net/aliases?api-version=2023-07-01-Preview"
```
