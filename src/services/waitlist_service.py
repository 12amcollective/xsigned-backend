from src.models.waitlist import Waitlist
from src.database.connection import get_db_session
from src.utils.validators import is_valid_email
import logging

logger = logging.getLogger(__name__)

class WaitlistService:
    """Service for handling waitlist operations"""
    
    @staticmethod
    def join_waitlist(email):
        """
        Add an email to the waitlist
        
        Args:
            email (str): Email address to add to waitlist
            
        Returns:
            tuple: (response_dict, status_code)
        """
        try:
            # Validate email format
            if not email or not is_valid_email(email):
                return {"error": "Valid email address is required"}, 400
            
            # Normalize email (lowercase)
            email = email.lower().strip()
            
            session = get_db_session()
            
            try:
                # Check if email already exists
                existing_entry = Waitlist.get_by_email(session, email)
                if existing_entry:
                    return {
                        "message": "You're already on the waitlist!", 
                        "email": email,
                        "joined_at": existing_entry.joined_at.isoformat()
                    }, 200
                
                # Create new waitlist entry
                waitlist_entry = Waitlist(email=email)
                session.add(waitlist_entry)
                session.commit()
                
                # Get total count for response
                total_count = Waitlist.count_total(session)
                
                logger.info(f"New waitlist signup: {email}")
                
                return {
                    "success": True,
                    "message": "Successfully joined the waitlist!",
                    "email": email,
                    "position": total_count,
                    "joined_at": waitlist_entry.joined_at.isoformat()
                }, 201
                
            except Exception as e:
                session.rollback()
                logger.error(f"Database error adding {email} to waitlist: {str(e)}")
                return {"error": "Failed to join waitlist"}, 500
                
            finally:
                session.close()
                
        except Exception as e:
            logger.error(f"Error in join_waitlist: {str(e)}")
            return {"error": "Internal server error"}, 500
    
    @staticmethod
    def get_waitlist_stats():
        """
        Get waitlist statistics
        
        Returns:
            tuple: (response_dict, status_code)
        """
        try:
            session = get_db_session()
            
            try:
                total_count = Waitlist.count_total(session)
                
                return {
                    "total_signups": total_count,
                    "status": "active"
                }, 200
                
            finally:
                session.close()
                
        except Exception as e:
            logger.error(f"Error getting waitlist stats: {str(e)}")
            return {"error": "Internal server error"}, 500
    
    @staticmethod
    def get_all_waitlist_entries():
        """
        Get all waitlist entries (admin endpoint)
        
        Returns:
            tuple: (response_dict, status_code)
        """
        try:
            session = get_db_session()
            
            try:
                entries = Waitlist.get_all(session)
                waitlist_data = [entry.to_dict() for entry in entries]
                
                return {
                    "waitlist": waitlist_data,
                    "total": len(waitlist_data)
                }, 200
                
            finally:
                session.close()
                
        except Exception as e:
            logger.error(f"Error getting waitlist entries: {str(e)}")
            return {"error": "Internal server error"}, 500
