from flask import Blueprint, request, jsonify
from src.services.waitlist_service import WaitlistService
import logging

logger = logging.getLogger(__name__)

waitlist_bp = Blueprint('waitlist', __name__, url_prefix='/api/waitlist')

@waitlist_bp.route('/join', methods=['POST'])
def join_waitlist():
    """Join the waitlist endpoint"""
    try:
        # Get data from request
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No data provided"}), 400
        
        email = data.get('email')
        
        if not email:
            return jsonify({"error": "Email is required"}), 400
        
        # Call service to handle the business logic
        result, status_code = WaitlistService.join_waitlist(email)
        return jsonify(result), status_code
        
    except Exception as e:
        logger.error(f"Error in join_waitlist endpoint: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@waitlist_bp.route('/stats', methods=['GET'])
def get_waitlist_stats():
    """Get waitlist statistics endpoint"""
    try:
        result, status_code = WaitlistService.get_waitlist_stats()
        return jsonify(result), status_code
        
    except Exception as e:
        logger.error(f"Error in get_waitlist_stats endpoint: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@waitlist_bp.route('/', methods=['GET'])
def get_all_waitlist_entries():
    """Get all waitlist entries endpoint (admin use)"""
    try:
        result, status_code = WaitlistService.get_all_waitlist_entries()
        return jsonify(result), status_code
        
    except Exception as e:
        logger.error(f"Error in get_all_waitlist_entries endpoint: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@waitlist_bp.route('/health', methods=['GET'])
def waitlist_health():
    """Health check for waitlist endpoints"""
    return jsonify({"status": "healthy", "service": "waitlist"}), 200
