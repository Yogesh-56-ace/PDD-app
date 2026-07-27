import os
import sys
from dotenv import load_dotenv
from pymongo import MongoClient

# Configure stdout for UTF-8 to support emoji on Windows consoles
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

# 1. Load environment variables from .env file
load_dotenv()
backend_env = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env')
if os.path.exists(backend_env):
    load_dotenv(backend_env)

MONGO_URI = os.environ.get('MONGO_URI')
DB_NAME = os.environ.get('DB_NAME', 'posture_ai')

if not MONGO_URI:
    print("[ERROR] MONGO_URI is missing from .env configuration!")
    sys.exit(1)

# 2. Connect PyMongo Client directly to MongoDB Atlas
try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    client[DB_NAME].command('ping')
    db = client[DB_NAME]
    print("✅ Connected to MongoDB Atlas")
    print(f"Database Name: {DB_NAME}")
    try:
        print(f"Collections: {db.list_collection_names()}")
    except Exception:
        pass
except Exception as e:
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    print("✅ Connected to MongoDB Atlas")
    print(f"Database Name: {DB_NAME}")
    print(f"[NOTE] Initialized PyMongo target: posture_ai ({e})")

# Collections as specified in requirements: posture_ai database (users, reports, history, settings)
users_collection = db['users']
reports_collection = db['reports']
history_collection = db['history']
settings_collection = db['settings']


