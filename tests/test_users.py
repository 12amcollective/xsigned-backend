import pytest
from src.models.user import User
from src.services.user_service import UserService

@pytest.fixture
def user_service():
    return UserService()

def test_create_user(user_service):
    user_data = {
        "email": "test@example.com"
    }
    user = user_service.create_user(user_data)
    assert user.email == user_data["email"]
    assert user.id is not None

def test_get_user(user_service):
    user_data = {
        "email": "test@example.com"
    }
    user = user_service.create_user(user_data)
    retrieved_user = user_service.get_user(user.id)
    assert retrieved_user.email == user.email

def test_create_user_invalid_email(user_service):
    user_data = {
        "email": "invalid-email"
    }
    with pytest.raises(ValueError):
        user_service.create_user(user_data)