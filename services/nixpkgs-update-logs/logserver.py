import os
import sys

# https://discourse.nixos.org/t/python-flask-app-cant-find-dependencies/6380
sys.argv[0] = os.path.dirname(sys.argv[0]) + '/.flask-wrapped'

from flask import Flask  # noqa
from flask_sqlalchemy import SQLAlchemy  # noqa

app = Flask(__name__)

db = SQLAlchemy()
app.config["SQLALCHEMY_DATABASE_URI"] = "postgresql+psycopg2://localhost:{port}/{db}".format(  # noqa
    port=os.getenv('DB_PORT'),
    db=os.getenv('DB_NAME'),
)
db.init_app(app)


@app.route("/")
def hello_world():
    data = db.metadata.tables.keys()
    return f"<h1>Hello, World!</h1><div>{data}</div>"
