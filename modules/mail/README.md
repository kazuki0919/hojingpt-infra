# Azure Communication Mail Service

### Prerequisites

1. The Azure resource provider must be registered with the Microsoft.Communication namespace.

```bash
# Check if the provider is registered
az provider list --query "[?namespace=='Microsoft.Communication']" --output table

# Register the provider
az provider register --namespace Microsoft.Communication
```

2. カスタムドメインの追加は手動で追加する必要があります。メール通信サービスの "ドメインをプロビジョニングする" から手動で追加してください。Domain/SPF/DKIM/DKIM2 全ての構成が必要です。Azure DNS へのレコード登録が必要になりますが、基本的に Azure Portal の指示に従えば問題なく登録できます。

3. デフォルトでは1分間で最大10通、一時間で最大100通しかメールが送信できません。サポートリクエストに投げて制限緩和の申請をしてください。以下は例です。リードタイムが数営業日発生するので余裕をもって対応する必要があります。

    ```
    [お問合せタイトル]
    Azure Communication Service のメール配信サービスの制限を引き上げたい

    [お問合せ内容]
    近々メール送信サービスを SendGrid から Azure Communication Service に移行することを計画しています。つきましては下記のとおり制限引き上げをお願いできますでしょうか？

    - Azure Communication Service リソース名: acs-hojingpt-prod-001
    - Email Serviceリソース名: acs-hojingpt-prod-mail-001
    - 希望のメール送信上限: 1000件/1分、30000件/1時間
    - 現行環境 (SendGrid) の配信流量: 過去最大で約 800件/分が2~3回程度
    - 送信に利用するドメイン: hojingpt.com (カスタムドメイン)
    - メール機能を利用する目的: 招待、パスワードリセット等
    - 会社名: Givery, Inc
    - 会社URL: https://givery.co.jp
    - 会社事業内容: AI、HRTech 領域等における SaaS 開発
    - 呼び出し元: Azure Container Apps
    - 送信元メールアドレス: no_reply@hojingpt.com
    - 送信先となるユーザーが配信解除を希望、もしくは送信不達となった場合の除外方法: 弊サービスからユーザーを除外することが可能
    ```
