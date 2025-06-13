from src.models.user import User
from src.database.connection import get_db_session
from sqlalchemy.exc import IntegrityError
import re

class UserService:
    
    @staticmethod
    def validate_email(email):
        """Basic email validation"""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None
    
    @staticmethod
    def create_user(email, artist_name=None):
        """Create a new user"""
        # Validate email format
        if not UserService.validate_email(email):
            return {"error": "Invalid email format"}, 400
        
        with get_db_session() as session:
            try:
                # Check if user already exists
                existing_user = User.get_by_email(session, email)
                if existing_user:
                    return {"error": "User with this email already exists"}, 409
                
                # Create new user
                new_user = User(
                    email=email.lower().strip(),
                    artist_name=artist_name.strip() if artist_name else None
                )
                
                session.add(new_user)
                session.commit()
                
                return {"user": new_user.to_dict(), "message": "User created successfully"}, 201
                
            except IntegrityError:
                session.rollback()
                return {"error": "User with this email already exists"}, 409
            except Exception as e:
                session.rollback()
                return {"error": f"Failed to create user: {str(e)}"}, 500
    
    @staticmethod
    def get_user_by_id(user_id):
        """Get user by ID"""
        with get_db_session() as session:
            try:
                user = User.get_by_id(session, user_id)
                if not user:
                    return {"error": "User not found"}, 404
                
                return {"user": user.to_dict()}, 200
                
            except Exception as e:
                return {"error": f"Failed to retrieve user: {str(e)}"}, 500
    
    @staticmethod
    def get_all_users():
        """Get all users"""
        with get_db_session() as session:
            try:
                users = User.get_all(session)
                return {"users": [user.to_dict() for user in users]}, 200
                
            except Exception as e:
                return {"error": f"Failed to retrieve users: {str(e)}"}, 500