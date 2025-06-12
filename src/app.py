from flask import Flask
from flask_cors import CORS
from src.routes.users import users_bp
from src.routes.campaigns import campaigns_bp
from src.database.connection import init_db
import os
import logging
from dotenv import load_dotenv

load_dotenv()

def create_app():
    app = Flask(__name__)
    
    # Production logging
    if os.getenv('FLASK_ENV') == 'production':
        logging.basicConfig(level=logging.INFO)
        app.logger.setLevel(logging.INFO)
    
    # Enable CORS for production domains
    cors_origins = [
        "http://localhost:3000",  # Development
        "https://xsigned.ai",     # Production
        "https://*.xsigned.ai"    # Subdomains
    ]
    CORS(app, origins=cors_origins)
    
    # Register blueprints
    app.register_blueprint(users_bp)
    app.register_blueprint(campaigns_bp)
    
    # Initialize database
    init_db()
    
    @app.route('/health', methods=['GET'])
    def health():
        return {"status": "healthy", "version": "1.0.0"}, 200
    
    return app

if __name__ == '__main__':
    app = create_app()
    
    # Production vs Development settings
    if os.getenv('FLASK_ENV') == 'production':
        app.run(host='0.0.0.0', port=5001)
    else:
        app.run(debug=True, host='0.0.0.0', port=5001)