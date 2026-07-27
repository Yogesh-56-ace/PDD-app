from flask import Blueprint, request, jsonify, g
from database.mongodb import db
from models.session_model import SessionModel
from middleware.auth_middleware import token_required
import uuid

session_bp = Blueprint('session', __name__)

@session_bp.route('/save-session', methods=['POST'])
@token_required
def save_session():
    """Manual analytics save endpoint directly saving into posture_ai.history."""
    data = request.get_json() or {}
    
    duration = data.get('duration')
    score = data.get('score')
    bad_posture_count = data.get('bad_posture_count')

    if duration is None or score is None or bad_posture_count is None:
        return jsonify({'message': 'Missing session analytics metrics!'}), 400

    try:
        session_id = str(uuid.uuid4())[:8]
        session = SessionModel(
            session_id=session_id,
            user_id=g.user_id,
            duration=int(duration),
            score=int(score),
            bad_posture_count=int(bad_posture_count),
            average_neck_angle=float(data.get('average_neck_angle', 0.0))
        )
        
        session_dict = session.to_dict()
        session_dict['_id'] = session_id
        db.history.insert_one(session_dict)

        return jsonify({
            'message': 'Session analytics recorded successfully.',
            'session_id': session_id
        }), 201
    except Exception as e:
        return jsonify({'message': f'Database write failure: {str(e)}'}), 500

@session_bp.route('/sessions/<user_id>', methods=['GET'])
@token_required
def get_user_sessions(user_id):
    """
    Returns all logged posture session summaries of a user from posture_ai.history.
    """
    if g.user_id != user_id:
        return jsonify({'message': 'Access Denied: Token ownership mismatch!'}), 403

    try:
        cursor = db.history.find({'user_id': user_id})
        
        sessions_list = []
        for doc in cursor:
            if '_id' in doc and not isinstance(doc['_id'], str):
                doc['_id'] = str(doc['_id'])
            sessions_list.append(doc)
            
        sessions_list.sort(key=lambda s: s.get('date', ''), reverse=True)

        return jsonify({'sessions': sessions_list}), 200
    except Exception as e:
        return jsonify({'message': f'Database query error: {str(e)}'}), 500

