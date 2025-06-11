def is_valid_email(email):
    import re
    email_regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    return re.match(email_regex, email) is not None

def validate_user_data(user_data):
    if 'email' not in user_data or not is_valid_email(user_data['email']):
        raise ValueError("Invalid email address.")
    # Additional validations can be added here
    return True

def validate_campaign_data(campaign_data):
    if 'name' not in campaign_data or not campaign_data['name']:
        raise ValueError("Campaign name is required.")
    # Additional validations can be added here
    return True