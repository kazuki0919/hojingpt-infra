from flask import Flask, jsonify, request
import mysql.connector

config = {
  'user': 'root',
  'password': 'XXXXXXXXXXXXXXXXXXXXXXX',
  'host': '10.200.1.3',
  'database': 'mysql',
}

app = Flask(__name__)

@app.route('/', methods=['GET'])
def hello():
    return jsonify({'message': 'hello!!!!'})

@app.route('/connect', methods=['GET'])
def connect_test():
  cnx = mysql.connector.connect(**config)
  if cnx.is_connected():
    print('Connected to MySQL database')
    cnx.close()
    return jsonify({'message': 'SUCCESS'})
  return jsonify({'message': 'FAILED'})

if __name__ == '__main__':
    app.run(debug=True)
