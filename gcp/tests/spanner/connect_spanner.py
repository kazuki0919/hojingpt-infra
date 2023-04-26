from google.cloud import spanner

# クライアント資格情報ファイルのパスを指定してSpannerクライアントを作成する
spanner_client = spanner.Client.from_service_account_json('/Users/yyoda/.gcp/service_accounts/hojingpt/hojingpt-staging-33aae0812e7b.json')

# Cloud Spannerインスタンスとデータベースの名前を指定する
instance_id = 'hojingpt-instance-staging'
database_id = 'hojingpt'

# インスタンスとデータベースを取得する
instance = spanner_client.instance(instance_id)
database = instance.database(database_id)

# クエリを実行する
with database.snapshot() as snapshot:
    results = snapshot.execute_sql('SELECT * FROM yoda_test')
    for row in results:
        print(row)
