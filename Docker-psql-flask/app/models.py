from flask_sqlalchemy import SQLAlchemy
from flask import Flask
from .config import Config

app = Flask(__name__)
app.config.from_object(Config)

db = SQLAlchemy(app)

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)  # Kullanıcı adı
    password = db.Column(db.String(128), nullable=False)  # Hashlenmiş şifre
    user_type = db.Column(db.String(50), nullable=False)  # Kullanıcı türü
    secret_question = db.Column(db.String(256))  # Gizli soru
    secret_answer = db.Column(db.String(128))  # Gizli sorunun cevabı (hashlenmiş)
    iban = db.Column(db.String(34))  # IBAN numarası

    # Backref for reports
    reports = db.relationship('Report', backref='user', lazy=True)

    def __repr__(self):
        return f'<User {self.username}>'

class Program(db.Model):
    __tablename__ = 'programs'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(256), nullable=False)  # Program adı
    description = db.Column(db.Text, nullable=False)  # Program açıklaması
    application_start_date = db.Column(db.DateTime, nullable=False)  # Başvuru tarihi
    application_end_date = db.Column(db.DateTime, nullable=False)  # Bitiş tarihi
    status = db.Column(db.String(50), nullable=False)  # Program durumu

    # Backref for reports with cascade delete
    reports = db.relationship('Report', backref='program', lazy=True, cascade='all, delete-orphan')

    def __repr__(self):
        return f'<Program {self.name}>'

class Report(db.Model):
    __tablename__ = 'reports'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)  # Kullanıcı kimliği
    program_id = db.Column(db.Integer, db.ForeignKey('programs.id'), nullable=False)  # Program kimliği
    report_pdf_path = db.Column(db.String(256), nullable=False)  # Raporun PDF yolu
    status = db.Column(db.String(50), nullable=False)  # Rapor durumu
    reward_amount = db.Column(db.Float)  # Ödül miktarı

    def __repr__(self):
        return f'<Report {self.id}>'
