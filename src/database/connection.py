from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session
import os
from contextlib import contextmanager
from src.database.base import Base
from dotenv import load_dotenv

load_dotenv()

# Database URL - construct from individual environment variables for Cloud Run compatibility
def get_database_url():
    # Try Cloud Run environment variables first
    db_host = os.getenv('DB_HOST')
    db_user = os.getenv('DB_USER', 'postgres')
    db_password = os.getenv('DB_PASSWORD')
    db_name = os.getenv('DB_NAME', 'xsigned_db')
    
    if db_host and db_password:
        # Cloud Run with Cloud SQL Unix socket
        if db_host.startswith('/cloudsql/'):
            return f'postgresql://{db_user}:{db_password}@/{db_name}?host={db_host}'
        # Cloud Run with Cloud SQL TCP
        else:
            return f'postgresql://{db_user}:{db_password}@{db_host}:5432/{db_name}'
    
    # Fallback to DATABASE_URL or default for local development
    return os.getenv(
        'DATABASE_URL', 
        'postgresql://backend_user:dev_password@localhost:5432/music_campaigns'
    )

DATABASE_URL = get_database_url()

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