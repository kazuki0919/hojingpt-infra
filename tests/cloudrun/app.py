from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/', methods=['GET'])
def hello():
    headers = dict(request.headers)
    return jsonify(headers)

if __name__ == '__main__':
    app.run(debug=True)
