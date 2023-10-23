# Azure Communication Mail Service

### Prerequisites

AOAI 構築後、各モデルの RateLimit を手動で調整する必要がある。未調整の場合は最小値が適用されるので注意。
基本方針として、本番環境は全体の 90% を割り当て、ステージング環境などへは残りを振り分けるような運用を想定している。
