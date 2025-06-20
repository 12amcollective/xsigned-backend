from flask import Flask
from flask_cors import CORS
from src.routes.users import users_bp
from src.routes.campaigns import campaigns_bp
from src.routes.waitlist import waitlist_bp
from src.database.connection import init_db
import os
import logging
from dotenv import load_dotenv

load_dotenv()

def create_app():
    app = Flask(__name__)
    
    # Configure Flask secret key for sessions and security
    app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', 'dev_secret_key_change_in_production')
    
    # Production logging
    if os.getenv('FLASK_ENV') == 'production':
        logging.basicConfig(level=logging.INFO)
        app.logger.setLevel(logging.INFO)
        # Additional security headers for production
        app.config['SESSION_COOKIE_SECURE'] = True
        app.config['SESSION_COOKIE_HTTPONLY'] = True
        app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
    
    # Enable CORS for production domains
    cors_origins = [
        "http://localhost:3000",        # Local development (default)
        "http://localhost:5173",        # Vite dev server default
        "http://localhost:5174",        # Your specific frontend port
        "http://127.0.0.1:5173",        # Local IP variants
        "http://127.0.0.1:5174",        
        "http://192.168.86.70:3000",   # Pi frontend container
        "http://192.168.86.70",        # Pi nginx proxy
        "https://xsigned.ai",          # Production domain
        "https://*.xsigned.ai",        # Subdomains
        "https://www.xsigned.ai"       # WWW subdomain
    ]
    CORS(app, origins=cors_origins, supports_credentials=True)
    
    # Basic health check (no database required)
    @app.route('/health', methods=['GET'])
    def health():
        return {"status": "healthy", "version": "1.0.0"}, 200
    
    # Always register blueprints first
    app.register_blueprint(users_bp)
    app.register_blueprint(campaigns_bp)
    app.register_blueprint(waitlist_bp)
    
    # Database initialization
    db_initialized = False
    db_error = None
    try:
        # Initialize database
        init_db()
        db_initialized = True
        
        @app.route('/db-status', methods=['GET'])
        def db_status():
            return {"status": "database_connected", "version": "1.0.0"}, 200
            
    except Exception as e:
        app.logger.error(f"Database initialization failed: {e}")
        db_error = str(e)
        # Create a fallback endpoint to show the error
        @app.route('/db-status', methods=['GET'])
        def db_status():
            return {"status": "database_error", "error": db_error}, 500
    
    return app

if __name__ == '__main__':
    app = create_app()
    
    # Get port from environment (Cloud Run uses PORT env var)
    port = int(os.getenv('PORT', 5001))
    
    # Production vs Development settings
    if os.getenv('FLASK_ENV') == 'production':
        app.run(host='0.0.0.0', port=port)
    else:
        app.run(debug=True, host='0.0.0.0', port=port)