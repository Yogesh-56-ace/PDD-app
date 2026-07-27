from flask import Blueprint, request, jsonify, g
from database.mongodb import db
from models.alert_model import AlertModel
from middleware.auth_middleware import token_required
import uuid
from datetime import datetime

alert_bp = Blueprint('alert', __name__)

@alert_bp.route('/alerts', methods=['POST'])
@token_required
def create_alert():
    """Records a poor posture warning alert log in Firestore."""
    data = request.get_json() or {}
    duration = data.get('duration', 0)
    suggestion = data.get('suggestion', "")
    alert_type = data.get('alert_type', "Spine")
    
    try:
        alert_id = str(uuid.uuid4())[:8]
        alert = AlertModel(
            alert_id=alert_id,
            user_id=g.user_id,
            timestamp=datetime.utcnow().isoformat() + 'Z',
            duration=int(duration),
            suggestion=suggestion,
            alert_type=alert_type
        )
        
        db.collection('alerts').document(alert_id).set(alert.to_dict())
        
        return jsonify({
            'message': 'Posture alert event persisted successfully.',
            'alert_id': alert_id
        }), 201
        
    except Exception as e:
        return jsonify({'message': f'Database write failure: {str(e)}'}), 500

@alert_bp.route('/alerts/<user_id>', methods=['GET'])
@token_required
def get_user_alerts(user_id):
    """Retrieves all logged alerts for an authenticated user."""
    if g.user_id != user_id:
        return jsonify({'message': 'Access Denied: Token ownership mismatch!'}), 403
        
    try:
        alerts_ref = db.collection('alerts').where('user_id', '==', user_id).get()
        
        alerts_list = []
        for doc in alerts_ref:
            alerts_list.append(doc.to_dict())
            
        # Sort alerts descending by timestamp
        alerts_list.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        
        return jsonify({'alerts': alerts_list}), 200
        
    except Exception as e:
        return jsonify({'message': f'Database query failure: {str(e)}'}), 500
