import os

class Config:
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'postgresql://admin:123456@db:5432/bugsheriff'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'abcdefgh'
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'abcdefg'
    JWT_TOKEN_LOCATION = ['headers']
    