# app/run.py

from flask import Flask, current_app as app
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from .models import db
from .config import Config
from flask_cors import CORS
from auth.routes import auth



app = Flask(__name__)
app.config.from_object(Config)  # Config sınıfını kullanarak ayarları yükle

CORS(app)
#CORS(app, resources={r"/*": {"origins": "http://localhost:52114"}})

db.init_app(app)
migrate = Migrate(app, db)
jwt = JWTManager(app)

app.register_blueprint(auth)

with app.app_context():
    db.create_all()
    

if __name__ == '__main__':
    app.run(debug=True)
