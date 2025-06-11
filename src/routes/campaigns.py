from flask import Blueprint, request, jsonify
from src.services.campaign_service import CampaignService

campaigns_bp = Blueprint('campaigns', __name__, url_prefix='/api/campaigns')

@campaigns_bp.route('/', methods=['POST'])
def create_campaign():
    """Create a new campaign endpoint"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No data provided"}), 400
            
        user_id = data.get('user_id')
        name = data.get('name')
        status = data.get('status')

        if not user_id or not name:
            return jsonify({'error': 'User ID and name are required'}), 400

        result, status_code = CampaignService.create_campaign(user_id, name, status)
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

@campaigns_bp.route('/<int:campaign_id>', methods=['GET'])
def get_campaign(campaign_id):
    """Get campaign by ID endpoint"""
    try:
        result, status_code = CampaignService.get_campaign(campaign_id)
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

@campaigns_bp.route('/<int:campaign_id>/progress', methods=['PATCH'])
def update_campaign_progress(campaign_id):
    """Update campaign progress endpoint"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No data provided"}), 400

        result, status_code = CampaignService.update_campaign_progress(campaign_id, data)
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500