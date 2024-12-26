#for docker
#app.run(host='0.0.0.0', port=8080)
from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello_world():
    return "This is Moon"


if __name__ == "__main__":
    app.run()
