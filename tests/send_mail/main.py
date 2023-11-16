import os
from azure.communication.email import EmailClient

connection_string = os.environ['CONNECTION_STRING']
email_count = os.environ.get('EMAIL_COUNT', 1)

# see: https://learn.microsoft.com/ja-jp/azure/communication-services/quickstarts/email/send-email-advanced/throw-exception-when-tier-limit-reached?pivots=programming-language-python
def callback(response):
  if 200 <= response.http_response.status_code <= 299:
    pass
  else:
    raise Exception(response.http_response) # 429 はここで検知される（テストで確認済）

if __name__ == "__main__":
  client = EmailClient.from_connection_string(connection_string, raw_response_hook=callback)
  for index in range(email_count):
    try:
      message = {
          "senderAddress": "no_reply@hojingpt.com",
          "recipients":  {
              "to": [{"address": "yusuke.yoda@givery.co.jp"}],
          },
          "content": {
              "subject": "Test Mail 0011",
              "plainText": f"Hello World. {index}",
          }
      }

      # 現在の Rate Limit は1分あたり1000通、1時間あたり30000通。超えると 429 が返る。
      # この Rate Limit はステージング環境と本番環境の両方に適用される。
      # Rate Limit の変更は MS のサポートに問い合わせる必要があり、2~3日かかる。
      poller = client.begin_send(message)

      # この処理でメール送信の完了を待ち受けることができるが、めちゃくちゃ遅いので非推奨
      # poller.result()

      print(f"succeeded: {index}")
    except Exception as e:
      print(e)  # callback で発生した Exception はここで検知される（テストで確認済）

  print("done")
