import os
from azure.communication.email import EmailClient

connection_string = os.environ['CONNECTION_STRING']
email_count = os.environ.get('EMAIL_COUNT', 1)

# see: https://learn.microsoft.com/ja-jp/azure/communication-services/quickstarts/email/send-email-advanced/throw-exception-when-tier-limit-reached?pivots=programming-language-python
def callback(response):
  if 200 <= response.http_response.status_code <= 299:
    pass
  else:
    raise Exception(response.http_response) # 429 はここで捕捉される

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
      # ステージング環境は1分あたり30通まで、1時間あたり100通までしか送信できない。超えると 429 が発生。
      # see: https://learn.microsoft.com/ja-jp/azure/communication-services/concepts/service-limits#email
      poller = client.begin_send(message)
      # poller.result()  # この処理は非推奨（めちゃくちゃ遅いので）
      print(f"succeeded: {index}")
    except Exception as e:
      print(e)  # callback で発生した Exception はここで捕獲される

  print("done")
