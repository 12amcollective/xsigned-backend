from src.models.campaign import Campaign, CampaignStatus
from src.database.connection import get_db_session
from sqlalchemy.exc import IntegrityError

class CampaignService:
    
    @staticmethod
    def create_campaign(user_id, name, status=None):
        """Create a new campaign"""
        if status is None:
            status = CampaignStatus.DRAFT
            
        with get_db_session() as session:
            try:
                new_campaign = Campaign(
                    user_id=user_id,
                    name=name,
                    status=status
                )
                session.add(new_campaign)
                session.commit()
                return {"campaign": new_campaign.get_campaign_info(), "message": "Campaign created successfully"}, 201
                
            except Exception as e:
                session.rollback()
                return {"error": f"Failed to create campaign: {str(e)}"}, 500

    @staticmethod
    def get_campaign(campaign_id):
        """Get campaign by ID"""
        with get_db_session() as session:
            try:
                campaign = Campaign.get_by_id(session, campaign_id)
                if not campaign:
                    return {"error": "Campaign not found"}, 404
                    
                return {"campaign": campaign.get_campaign_info()}, 200
                
            except Exception as e:
                return {"error": f"Failed to retrieve campaign: {str(e)}"}, 500

    @staticmethod
    def update_campaign_progress(campaign_id, progress_data):
        """Update campaign progress"""
        with get_db_session() as session:
            try:
                campaign = Campaign.get_by_id(session, campaign_id)
                if not campaign:
                    return {"error": "Campaign not found"}, 404
                
                # Update campaign with progress data
                campaign.update_campaign(session, progress_data)
                
                return {"campaign": campaign.get_campaign_info(), "message": "Campaign updated successfully"}, 200
                
            except Exception as e:
                session.rollback()
                return {"error": f"Failed to update campaign: {str(e)}"}, 500

    def get_campaign(self, campaign_id):
        return self.db.session.query(Campaign).filter_by(id=campaign_id).first()

    def get_all_campaigns(self):
        return self.db.session.query(Campaign).all()