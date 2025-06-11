# xSigned Campaign Manager Backend

This project is a backend web application designed to collect user information and manage records for a music marketing campaign manager. It is built using Flask and provides endpoints for user and campaign management.

## Features

- User registration and information retrieval
- Campaign creation and progress tracking
- Input validation for user data
- Database connection management

## Project Structure

```
music-campaign-backend
├── src
│   ├── app.py                # Entry point of the application
│   ├── models                # Contains data models
│   │   ├── user.py           # User model
│   │   └── campaign.py       # Campaign model
│   ├── routes                # Contains route definitions
│   │   ├── users.py          # User-related routes
│   │   └── campaigns.py      # Campaign-related routes
│   ├── services              # Contains business logic
│   │   ├── user_service.py   # User-related services
│   │   └── campaign_service.py# Campaign-related services
│   ├── database              # Database connection management
│   │   └── connection.py     # Database connection setup
│   └── utils                 # Utility functions
│       └── validators.py     # Input validation functions
├── migrations                 # Database migrations
├── tests                     # Unit tests
├── requirements.txt          # Project dependencies
├── config.py                 # Configuration settings
└── README.md                 # Project documentation
```

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   cd music-campaign-backend
   ```

2. Install the required dependencies:
   ```
   pip install -r requirements.txt
   ```

3. Configure the application settings in `config.py`.

4. Run the application:
   ```
   python src/app.py
   ```

## Usage

- Use the `/users` endpoint to register and retrieve user information.
- Use the `/campaigns` endpoint to create and manage campaigns.

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.
