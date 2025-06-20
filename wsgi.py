#!/usr/bin/env python3
"""
WSGI entry point for Google Cloud Run deployment.
This file creates the Flask application instance that Gunicorn can serve.
"""

import sys
import os
import traceback

# Store the error for use in the dummy app
initialization_error = None

try:
    from src.app import create_app
    
    # Create the Flask application instance
    app = create_app()
    print("Flask app created successfully", file=sys.stderr)
    
except Exception as e:
    initialization_error = str(e)
    error_traceback = traceback.format_exc()
    print(f"Failed to create Flask app: {str(e)}", file=sys.stderr)
    print(f"Traceback: {error_traceback}", file=sys.stderr)
    
    # Create a dummy app so Gunicorn doesn't fail completely
    from flask import Flask
    app = Flask(__name__)
    
    @app.route('/health')
    def health():
        return {"error": "App failed to initialize", "details": initialization_error, "traceback": error_traceback}, 500

if __name__ == "__main__":
    app.run()
