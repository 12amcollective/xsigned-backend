from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
from contextlib import contextmanager
from .base import Base

# Database URL - update with your PostgreSQL credentials
DATABASE_URL = os.getenv(
    'DATABASE_URL', 
    'postgresql://home@localhost:5432/music_campaigns'
)

engine = create_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@contextmanager
def get_db_session():
    """Context manager for database sessions"""
    session = SessionLocal()
    try:
        yield session
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

def init_db():
    """Initialize the database with all tables"""
    # Import models here to avoid circular imports
    from src.models.user import User
    from src.models.campaign import Campaign, CampaignTask
    Base.metadata.create_all(bind=engine)