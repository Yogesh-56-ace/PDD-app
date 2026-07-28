from flask import Blueprint, request, jsonify, g
from database.mongodb import db
from middleware.auth_middleware import token_required
from services.auth_service import AuthService

user_bp = Blueprint('user', __name__)

@user_bp.route('/user/onboarding', methods=['POST'])
@token_required
def complete_onboarding():
    """Updates user document in PyMongo MongoDB Atlas posture_ai.users to set onboarding_completed = True."""
    try:
        user_doc = db.users.find_one({'_id': g.user_id}) or db.users.find_one({'user_id': g.user_id})
        if not user_doc:
            db.users.insert_one({
                '_id': g.user_id,
                'user_id': g.user_id,
                'email': g.email,
                'onboarding_completed': True
            })
        else:
            db.users.update_one(
                {'$or': [{'_id': g.user_id}, {'user_id': g.user_id}]},
                {'$set': {'onboarding_completed': True}}
            )

        print(f"[DB] Onboarding completed status recorded in MongoDB Atlas for user {g.user_id}")
        return jsonify({'message': 'Onboarding state persisted successfully.', 'onboarding_completed': True}), 200
        
    except Exception as e:
        return jsonify({'message': f'Database write failure: {str(e)}'}), 500

@user_bp.route('/user/status', methods=['GET'])
@token_required
def get_user_status():
    """Retrieves user onboarding and diagnostic stats from posture_ai.users."""
    try:
        user_doc = db.users.find_one({'_id': g.user_id}) or db.users.find_one({'user_id': g.user_id})
        if not user_doc:
            return jsonify({'onboarding_completed': False}), 200
            
        return jsonify({
            'user_id': g.user_id,
            'name': user_doc.get('name'),
            'email': user_doc.get('email'),
            'age': user_doc.get('age'),
            'gender': user_doc.get('gender'),
            'profile_image': user_doc.get('profile_image'),
            'onboarding_completed': user_doc.get('onboarding_completed', False)
        }), 200
        
    except Exception as e:
        return jsonify({'message': f'Database read failure: {str(e)}'}), 500

@user_bp.route('/user/avatar', methods=['POST'])
@token_required
def upload_avatar():
    """
    Uploads a new user profile picture directly to Cloudinary and saves URL in posture_ai.users.
    """
    file = request.files.get('file') or request.files.get('avatar')
    data = request.get_json() or {}
    image_source = file or data.get('profile_image') or data.get('image')

    if not image_source:
        return jsonify({'message': 'No avatar image file or data provided!'}), 400

    try:
        from services.cloudinary_service import upload_image_to_cloudinary
        cloudinary_url = upload_image_to_cloudinary(image_source, folder="posture-ai/avatars")
        
        db.users.update_one(
            {'$or': [{'_id': g.user_id}, {'user_id': g.user_id}]},
            {'$set': {'profile_image': cloudinary_url}},
            upsert=True
        )

        print(f"[DB] Updated profile_image for user {g.user_id}: {cloudinary_url}")
        return jsonify({
            'status': 'success',
            'message': 'Profile picture updated successfully!',
            'profile_image': cloudinary_url
        }), 200
    except Exception as e:
        print(f"[AVATAR ERROR] Upload avatar failed: {e}")
        return jsonify({'message': f'Avatar upload failure: {str(e)}'}), 500

@user_bp.route('/user/profile', methods=['PUT'])
@token_required
def update_profile():
    """Updates user information including name, age, gender, and profile avatar in posture_ai.users."""
    data = request.get_json() or {}
    
    try:
        user_doc = db.users.find_one({'_id': g.user_id}) or db.users.find_one({'user_id': g.user_id})
        if not user_doc:
            return jsonify({'message': 'User not found!'}), 404
            
        update_data = {}
        if 'name' in data and data['name']:
            update_data['name'] = data['name']
        if 'age' in data:
            try:
                if str(data['age']).strip() == '':
                    update_data['age'] = None
                else:
                    age_val = int(data['age'])
                    if age_val < 0 or age_val > 120:
                        return jsonify({'message': 'Please enter a valid age range (0-120).'}), 400
                    update_data['age'] = age_val
            except (ValueError, TypeError):
                return jsonify({'message': 'Age must be a valid integer.'}), 400
        if 'gender' in data:
            gender_val = data['gender']
            if gender_val and gender_val not in ['Male', 'Female', 'Other']:
                return jsonify({'message': 'Gender must be Male, Female, or Other.'}), 400
            update_data['gender'] = gender_val
        if 'profile_image' in data:
            update_data['profile_image'] = data['profile_image']
            
        if not update_data:
            return jsonify({'message': 'No valid update parameters provided.'}), 400
            
        db.users.update_one(
            {'$or': [{'_id': g.user_id}, {'user_id': g.user_id}]},
            {'$set': update_data}
        )
        
        latest_user = db.users.find_one({'_id': g.user_id}) or db.users.find_one({'user_id': g.user_id}) or {}
        return jsonify({
            'message': 'Profile updated successfully!',
            'user': {
                'user_id': g.user_id,
                'name': latest_user.get('name'),
                'email': latest_user.get('email'),
                'age': latest_user.get('age'),
                'gender': latest_user.get('gender'),
                'profile_image': latest_user.get('profile_image'),
                'onboarding_completed': latest_user.get('onboarding_completed', False)
            }
        }), 200
        
    except Exception as e:
        return jsonify({'message': f'Profile update failure: {str(e)}'}), 500

@user_bp.route('/user/change-password', methods=['PUT'])
@token_required
def change_password():
    """Allows authenticated users to change their password securely in posture_ai.users."""
    data = request.get_json() or {}
    new_password = data.get('new_password')
    
    if not new_password or len(new_password) < 6:
        return jsonify({'message': 'Password must be at least 6 characters long.'}), 400
        
    try:
        user_doc = db.users.find_one({'_id': g.user_id}) or db.users.find_one({'user_id': g.user_id})
        if not user_doc:
            return jsonify({'message': 'User not found!'}), 404
            
        hashed_password = AuthService.hash_password(new_password)
        db.users.update_one(
            {'$or': [{'_id': g.user_id}, {'user_id': g.user_id}]},
            {'$set': {'password_hash': hashed_password}}
        )
        
        return jsonify({'message': 'Password changed successfully!'}), 200
    except Exception as e:
        return jsonify({'message': f'Password change failure: {str(e)}'}), 500


