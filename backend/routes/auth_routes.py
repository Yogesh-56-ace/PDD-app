from flask import Blueprint, request, jsonify
import uuid
import sys
from database.mongodb import db
from models.settings_model import SettingsModel
from services.auth_service import AuthService

import re

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    """Registers a new user directly in PyMongo MongoDB Atlas posture_ai.users collection."""
    data = request.get_json() or {}
    print(f"\n[REGISTRATION REQUEST] Incoming payload: name={data.get('name')}, email={data.get('email')}")
    
    name = data.get('name')
    raw_email = data.get('email', '')
    password = data.get('password')
    age = data.get('age')
    gender = data.get('gender')

    if not name or not raw_email or not password:
        print("[REGISTRATION WARN] Missing mandatory registration credentials!")
        return jsonify({'message': 'Missing mandatory registration credentials!', 'error': 'Missing name, email, or password'}), 400

    clean_email = str(raw_email).strip().lower()

    try:
        # 1. Case-insensitive check if user already exists in db.users
        print(f"[REGISTRATION LOG] Checking db.users for existing email={clean_email}...")
        existing_user = db.users.find_one({'email': {'$regex': f'^{re.escape(clean_email)}$', '$options': 'i'}})

        if existing_user:
            print(f"[REGISTRATION WARN] Account already exists for email: {clean_email}")
            return jsonify({'message': 'A user account with this email already exists!', 'error': 'User account already exists'}), 409

        # 2. Validate age if present
        validated_age = None
        if age is not None and str(age).strip() != '':
            try:
                validated_age = int(age)
                if validated_age < 0 or validated_age > 120:
                    return jsonify({'message': 'Please enter a valid age range (0-120).', 'error': 'Invalid age range'}), 400
            except ValueError:
                return jsonify({'message': 'Age must be a valid number.', 'error': 'Invalid age format'}), 400

        # 3. Validate gender if present
        validated_gender = None
        if gender:
            if gender not in ['Male', 'Female', 'Other']:
                return jsonify({'message': 'Gender must be Male, Female, or Other.', 'error': 'Invalid gender'}), 400
            validated_gender = gender

        # 4. Generate user_id and hash password using Bcrypt
        user_id = str(uuid.uuid4())
        hashed_password = AuthService.hash_password(password)

        # 5. Build user document for posture_ai.users collection
        user_doc = {
            '_id': user_id,
            'user_id': user_id,
            'name': name,
            'email': clean_email,
            'password_hash': hashed_password,
            'age': validated_age,
            'gender': validated_gender,
            'profile_image': None,
            'onboarding_completed': False
        }

        # 6. Insert into db.users
        print(f"[REGISTRATION INSERT] Saving user document _id={user_id}, email={clean_email}...")
        insert_result = db.users.insert_one(user_doc)
        print(f"[REGISTRATION INSERT OK] acknowledged={insert_result.acknowledged}, inserted_id={insert_result.inserted_id}")

        # 7. Create default settings
        default_settings = SettingsModel(user_id=user_id).to_dict()
        default_settings['_id'] = user_id
        db.settings.insert_one(default_settings)

        # 8. Issue JWT token
        token = AuthService.generate_token(user_id, clean_email)

        return jsonify({
            'message': 'Registration successful!',
            'token': token,
            'user': {
                'user_id': user_id,
                'name': name,
                'email': clean_email,
                'age': validated_age,
                'gender': validated_gender,
                'profile_image': None,
                'onboarding_completed': False
            }
        }), 201

    except Exception as e:
        print(f"[REGISTRATION ERROR] Exception: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return jsonify({'message': f'MongoDB Atlas Registration Error: {str(e)}', 'error': str(e)}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    """Authenticates returning users directly using case-insensitive email query and Bcrypt audit."""
    data = request.get_json() or {}
    raw_email = data.get('email', '')
    password = data.get('password')

    if not raw_email or not password:
        return jsonify({'message': 'Missing email or password credentials!', 'error': 'Missing credentials'}), 400

    clean_email = str(raw_email).strip().lower()

    try:
        # Case-insensitive email query in posture_ai.users
        print(f"[LOGIN LOG] Searching db.users for email={clean_email}...")
        user_doc = db.users.find_one({'email': {'$regex': f'^{re.escape(clean_email)}$', '$options': 'i'}})

        if not user_doc:
            print(f"[LOGIN WARN] User not found for email: {clean_email}")
            return jsonify({'message': 'Invalid login credentials!', 'error': 'User not found'}), 401

        # Audit password with Bcrypt
        stored_hash = user_doc.get('password_hash', '')
        is_password_valid = AuthService.check_password(password, stored_hash)
        if not is_password_valid:
            print(f"[LOGIN WARN] Invalid password for email: {clean_email}")
            return jsonify({'message': 'Invalid login credentials!', 'error': 'Incorrect password'}), 401

        user_id = user_doc.get('user_id', str(user_doc.get('_id', '')))
        user_email = user_doc.get('email', clean_email)
        
        # Issue signed JWT token
        token = AuthService.generate_token(user_id, user_email)

        return jsonify({
            'message': 'Authentication successful!',
            'token': token,
            'user': {
                'user_id': user_id,
                'name': user_doc.get('name'),
                'email': user_email,
                'age': user_doc.get('age'),
                'gender': user_doc.get('gender'),
                'profile_image': user_doc.get('profile_image'),
                'onboarding_completed': user_doc.get('onboarding_completed', False)
            }
        }), 200

    except Exception as e:
        print(f"[LOGIN ERROR] Exception: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return jsonify({'message': f'MongoDB Atlas Login Error: {str(e)}', 'error': str(e)}), 500


