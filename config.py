import os

class Config:
    DEBUG = os.environ.get('DEBUG', 'False') == 'True'
    DATABASE_URI = os.environ.get('DATABASE_URI', 'sqlite:///default.db')
    SECRET_KEY = os.environ.get('SECRET_KEY', 'your_secret_key')
    MAIL_SERVER = os.environ.get('MAIL_SERVER', 'smtp.example.com')
    MAIL_PORT = int(os.environ.get('MAIL_PORT', 587))
    MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS', 'True') == 'True'
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME', 'your_email@example.com')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD', 'your_password')