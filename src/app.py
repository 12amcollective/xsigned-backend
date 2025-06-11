from flask import Flask
from flask_cors import CORS
from src.routes.users import users_bp
from src.routes.campaigns import campaigns_bp
from src.database.connection import init_db
import os
from dotenv import load_dotenv

load_dotenv()

def create_app():
    app = Flask(__name__)
    
    # Enable CORS for React frontend
    CORS(app, origins=["http://localhost:3000"])
    
    # Register blueprints
    app.register_blueprint(users_bp)
    app.register_blueprint(campaigns_bp)
    
    # Initialize database
    init_db()
    
    @app.route('/health', methods=['GET'])
    def health():
        return {"status": "healthy"}, 200
    
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5001)