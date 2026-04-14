from flask import Flask

app = Flask(__name__)


@app.route("/")
def main():
    return "CI/CD"


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8080, debug=True)
