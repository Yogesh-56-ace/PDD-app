from flask import Blueprint, request, jsonify, g
from database.mongodb import db
from models.settings_model import SettingsModel
from middleware.auth_middleware import token_required

settings_bp = Blueprint('settings', __name__)

@settings_bp.route('/settings/<user_id>', methods=['GET'])
@token_required
def get_settings(user_id):
    """Retrieves user settings preferences from posture_ai.settings."""
    if g.user_id != user_id:
        return jsonify({'message': 'Access Denied: Token ownership mismatch!'}), 403

    try:
        settings_doc = db.settings.find_one({'_id': user_id}) or db.settings.find_one({'user_id': user_id}) or {}
        settings = SettingsModel.from_dict(settings_doc, user_id)
        
        return jsonify({'settings': settings.to_dict()}), 200
    except Exception as e:
        return jsonify({'message': f'Settings lookup failure: {str(e)}'}), 500

@settings_bp.route('/settings/<user_id>', methods=['PUT'])
@token_required
def update_settings(user_id):
    """Updates user notification preferences and posture sensitivity settings in posture_ai.settings."""
    if g.user_id != user_id:
        return jsonify({'message': 'Access Denied: Token ownership mismatch!'}), 403

    data = request.get_json() or {}
    
    try:
        updated_data = {}
        if 'audio_alert' in data:
            updated_data['audio_alert'] = bool(data['audio_alert'])
        if 'sensitivity' in data:
            sensitivity = data['sensitivity']
            if sensitivity in ['low', 'medium', 'high']:
                updated_data['sensitivity'] = sensitivity
        if 'reminder_interval' in data:
            updated_data['reminder_interval'] = int(data['reminder_interval'])

        if not updated_data:
            return jsonify({'message': 'No valid configurations provided for update.'}), 400

        db.settings.update_one(
            {'$or': [{'_id': user_id}, {'user_id': user_id}]},
            {'$set': updated_data},
            upsert=True
        )

        latest_doc = db.settings.find_one({'_id': user_id}) or db.settings.find_one({'user_id': user_id}) or {}
        latest_settings = SettingsModel.from_dict(latest_doc, user_id)

        return jsonify({
            'message': 'Preferences updated successfully.',
            'settings': latest_settings.to_dict()
        }), 200

    except Exception as e:
        return jsonify({'message': f'Settings write failure: {str(e)}'}), 500

