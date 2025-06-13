from flask import Blueprint, request, jsonify
from src.services.user_service import UserService

users_bp = Blueprint('users', __name__, url_prefix='/api/users')

@users_bp.route('/', methods=['GET'])
def get_all_users():
    """Get all users endpoint"""
    try:
        result, status_code = UserService.get_all_users()
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

@users_bp.route('/', methods=['POST'])
def create_user():
    """Create a new user endpoint"""
    try:
        # Get data from request
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No data provided"}), 400
        
        email = data.get('email')
        artist_name = data.get('artist_name')
        
        # Validate required fields
        if not email:
            return jsonify({"error": "Email is required"}), 400
        
        # Create user using service
        result, status_code = UserService.create_user(email, artist_name)
        
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

@users_bp.route('/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Get user by ID endpoint"""
    try:
        result, status_code = UserService.get_user_by_id(user_id)
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

@users_bp.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy"}), 200