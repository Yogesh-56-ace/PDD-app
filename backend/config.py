import os
from dotenv import load_dotenv

# Load environmental variables
load_dotenv()

class Config:
    # Security Configurations
    SECRET_KEY = os.environ.get('SECRET_KEY', 'posture_fix_pro_super_secret_jwt_key_123!')
    JWT_ALGORITHM = 'HS256'
    JWT_EXPIRATION_HOURS = 24

    # Firebase Admin SDK Credentials Configuration
    # Defaults to local service account key file if available, otherwise initialized using fallback credentials
    FIREBASE_CREDENTIALS = os.environ.get('FIREBASE_CREDENTIALS', 'database/firebase_key.json')
    
    # Server configuration
    PORT = int(os.environ.get('PORT', 5000))
    DEBUG = os.environ.get('DEBUG', 'True').lower() == 'true'

    # Cloudinary Configurations
    CLOUDINARY_CLOUD_NAME = os.environ.get('CLOUDINARY_CLOUD_NAME', 'sys2leas')
    CLOUDINARY_API_KEY = os.environ.get('CLOUDINARY_API_KEY', '995613675478516')
    CLOUDINARY_API_SECRET = os.environ.get('CLOUDINARY_API_SECRET', 'cp7KCq5bNtyWJ3BXppLhJ8XPXas')
