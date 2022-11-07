import os
import sys

# https://discourse.nixos.org/t/python-flask-app-cant-find-dependencies/6380
sys.argv[0] = os.path.dirname(sys.argv[0]) + '/.flask-wrapped'

from flask import Flask
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)

db = SQLAlchemy()
dbport = os.getenv('DB_PORT')
app.config[
    "SQLALCHEMY_DATABASE_URI"] = f"postgresql+psycopg2://localhost:${dbport}"
db.init_app(app)


@app.route("/")
def hello_world():
    data = db.metadata.tables.keys()
    return f"<h1>Hello, World!</h1><div>{data}</div>"
