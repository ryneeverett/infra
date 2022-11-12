import os
import sys

# https://discourse.nixos.org/t/python-flask-app-cant-find-dependencies/6380
sys.argv[0] = os.path.dirname(sys.argv[0]) + '/.flask-wrapped'

from flask import Flask  # noqa
from flask_sqlalchemy import SQLAlchemy  # noqa

app = Flask(__name__)

db = SQLAlchemy()
# TODO connect to PACKAGE_DB too
app.config["SQLALCHEMY_DATABASE_URI"] = "postgresql+psycopg2://{user}@:{port}/{db}".format(  # noqa
    user=os.getenv('DB_USER'),
    port=os.getenv('DB_PORT'),
    db=os.getenv('FETCHER_DB'),
)
db.init_app(app)


@app.route("/")
def hello_world():
    data = db.engine.table_names()
    return f"<h1>Hello, World!</h1><div>{data}</div>"
