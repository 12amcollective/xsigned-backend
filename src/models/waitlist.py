from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from src.database.base import Base

class Waitlist(Base):
    __tablename__ = 'waitlist'
    
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False)
    joined_at = Column(DateTime, default=datetime.utcnow)
    is_notified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
    
    @classmethod
    def get_by_email(cls, session, email):
        """Get waitlist entry by email"""
        return session.query(cls).filter_by(email=email).first()
    
    @classmethod
    def get_all(cls, session):
        """Get all waitlist entries"""
        return session.query(cls).order_by(cls.joined_at.desc()).all()
    
    @classmethod
    def count_total(cls, session):
        """Get total count of waitlist entries"""
        return session.query(cls).count()