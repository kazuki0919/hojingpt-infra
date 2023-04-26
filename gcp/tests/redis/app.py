from flask import Flask, jsonify, request
import redis

redis_host = "10.200.0.3"
redis_port = 6379
redis_password = ""

redis_client = redis.StrictRedis(host=redis_host, port=redis_port, password=redis_password, decode_responses=True)

app = Flask(__name__)

@app.route('/', methods=['GET'])
def hello():
    return jsonify({'message': 'hello!!!!'})

@app.route('/data', methods=['POST'])
def save_data():
    data = request.get_json()
    redis_client.setex(data['key'], 10, data['value'])
    return jsonify({'message': 'データを保存しました'})

@app.route('/data/<string:key>', methods=['GET'])
def get_data(key):
    value = redis_client.get(key)
    if value:
        return jsonify({'value': value})
    else:
        return jsonify({'message': 'データが見つかりませんでした'})

if __name__ == '__main__':
    app.run(debug=True)
