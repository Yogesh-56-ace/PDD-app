from flask import Blueprint, request, jsonify
import uuid
import sys
from database.mongodb import db
from models.settings_model import SettingsModel
from services.auth_service import AuthService

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    """Registers a new user directly in PyMongo MongoDB Atlas posture_ai.users collection."""
    data = request.get_json() or {}
    print(f"\n[REGISTRATION REQUEST] Incoming request payload: name={data.get('name')}, email={data.get('email')}, age={data.get('age')}, gender={data.get('gender')}")
    
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    age = data.get('age')
    gender = data.get('gender')

    if not name or not email or not password:
        print("[REGISTRATION WARN] Missing mandatory registration credentials!")
        return jsonify({'message': 'Missing mandatory registration credentials!', 'error': 'Missing name, email, or password'}), 400

    try:
        # 1. Check if user already exists using db.users.find_one()
        print(f"[REGISTRATION LOG] Executing db.users.find_one for email={email}...")
        existing_user = db.users.find_one({'email': email})

        if existing_user:
            print(f"[REGISTRATION WARN] Account already exists for email: {email}")
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
            'email': email,
            'password_hash': hashed_password,
            'age': validated_age,
            'gender': validated_gender,
            'profile_image': None,
            'onboarding_completed': False
        }

        # 6. Logging before and after db.users.insert_one() call
        print(f"[REGISTRATION BEFORE INSERT] Executing db.users.insert_one() for _id={user_id}, email={email}...")
        insert_result = db.users.insert_one(user_doc)
        print(f"[REGISTRATION AFTER INSERT] db.users.insert_one() finished! acknowledged={insert_result.acknowledged}, inserted_id={insert_result.inserted_id}")

        # 7. Logging before and after db.settings.insert_one() call
        default_settings = SettingsModel(user_id=user_id).to_dict()
        default_settings['_id'] = user_id
        print(f"[SETTINGS BEFORE INSERT] Executing db.settings.insert_one() for _id={user_id}...")
        settings_insert = db.settings.insert_one(default_settings)
        print(f"[SETTINGS AFTER INSERT] db.settings.insert_one() finished! acknowledged={settings_insert.acknowledged}, inserted_id={settings_insert.inserted_id}")

        # 8. Issue JWT token
        token = AuthService.generate_token(user_id, email)

        return jsonify({
            'message': 'Registration successful!',
            'token': token,
            'user': {
                'user_id': user_id,
                'name': name,
                'email': email,
                'age': validated_age,
                'gender': validated_gender,
                'profile_image': None,
                'onboarding_completed': False
            }
        }), 201

    except Exception as e:
        print(f"[REGISTRATION FAILURE EXCEPTION] Full Exception in Flask Console: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return jsonify({'message': f'MongoDB Atlas Registration Error: {str(e)}', 'error': str(e)}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    """Authenticates returning users directly using db.users.find_one()."""
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'message': 'Missing email or password credentials!', 'error': 'Missing credentials'}), 400

    try:
        # Direct PyMongo find_one() query in posture_ai.users
        print(f"[LOGIN LOG] Executing db.users.find_one for email={email}...")
        user_doc = db.users.find_one({'email': email})

        if not user_doc:
            print(f"[LOGIN WARN] User not found for email: {email}")
            return jsonify({'message': 'Invalid login credentials!', 'error': 'User not found'}), 401

        # Audit password with Bcrypt
        is_password_valid = AuthService.check_password(password, user_doc.get('password_hash', ''))
        if not is_password_valid:
            print(f"[LOGIN WARN] Invalid password for email: {email}")
            return jsonify({'message': 'Invalid login credentials!', 'error': 'Incorrect password'}), 401

        user_id = user_doc.get('user_id', str(user_doc.get('_id', '')))
        
        # Issue signed JWT token
        token = AuthService.generate_token(user_id, email)

        return jsonify({
            'message': 'Authentication successful!',
            'token': token,
            'user': {
                'user_id': user_id,
                'name': user_doc.get('name'),
                'email': email,
                'age': user_doc.get('age'),
                'gender': user_doc.get('gender'),
                'profile_image': user_doc.get('profile_image'),
                'onboarding_completed': user_doc.get('onboarding_completed', False)
            }
        }), 200

    except Exception as e:
        print(f"[LOGIN EXCEPTION] Full Exception in Flask Console: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return jsonify({'message': f'MongoDB Atlas Login Error: {str(e)}', 'error': str(e)}), 500


