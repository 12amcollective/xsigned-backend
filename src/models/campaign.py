from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON, Enum, Boolean
from sqlalchemy.orm import relationship, sessionmaker
from datetime import datetime
import enum
from src.database.base import Base

class CampaignStatus(enum.Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"

class Campaign(Base):
    __tablename__ = 'campaigns'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    name = Column(String(255), nullable=False)
    status = Column(Enum(CampaignStatus), default=CampaignStatus.DRAFT)
    campaign_data = Column(JSON)  # For flexible campaign data (renamed from metadata)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="campaigns")
    tasks = relationship("CampaignTask", back_populates="campaign", cascade="all, delete-orphan")

    def create_campaign(self, session):
        """Create a new campaign record in the database"""
        try:
            session.add(self)
            session.commit()
            return True
        except Exception as e:
            session.rollback()
            raise e

    def update_campaign(self, session, new_data):
        """Update the campaign record with new data"""
        try:
            for key, value in new_data.items():
                if hasattr(self, key):
                    setattr(self, key, value)
            self.updated_at = datetime.utcnow()
            session.commit()
            return True
        except Exception as e:
            session.rollback()
            raise e

    def get_campaign_info(self):
        """Retrieve campaign information"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "name": self.name,
            "status": self.status.value if self.status else None,
            "campaign_data": self.campaign_data,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }

    @classmethod
    def get_by_id(cls, session, campaign_id):
        """Get campaign by ID"""
        return session.query(cls).filter(cls.id == campaign_id).first()

    @classmethod
    def get_by_user(cls, session, user_id):
        """Get all campaigns for a user"""
        return session.query(cls).filter(cls.user_id == user_id).all()

class CampaignTask(Base):
    __tablename__ = 'campaign_tasks'
    
    id = Column(Integer, primary_key=True)
    campaign_id = Column(Integer, ForeignKey('campaigns.id'), nullable=False)
    task_name = Column(String(255), nullable=False)
    description = Column(String(1000))
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    campaign = relationship("Campaign", back_populates="tasks")
    
    def mark_completed(self, session):
        """Mark task as completed"""
        self.completed = True
        self.completed_at = datetime.utcnow()
        session.commit()