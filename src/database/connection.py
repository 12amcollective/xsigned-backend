from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session
import os
from contextlib import contextmanager
from src.database.base import Base
from dotenv import load_dotenv

load_dotenv()

# Database URL - update with your PostgreSQL credentials
DATABASE_URL = os.getenv(
    'DATABASE_URL', 
    'postgresql://backend_user:dev_password@localhost:5432/music_campaigns'
)

engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = scoped_session(sessionmaker(autocommit=False, autoflush=False, bind=engine))

@contextmanager
def get_db_session():
    """Context manager for database sessions"""
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

def init_db():
    """Initialize the database with all tables"""
    # Import models here to avoid circular imports
    from src.models.user import User
    from src.models.campaign import Campaign, CampaignTask
    from src.models.waitlist import Waitlist  # Add this import
    
    # Create all tables
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created successfully")