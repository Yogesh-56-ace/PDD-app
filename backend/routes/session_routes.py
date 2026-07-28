from flask import Blueprint, request, jsonify, g
from database.mongodb import db
from models.session_model import SessionModel
from datetime import datetime
import uuid
import jwt
from config import Config

session_bp = Blueprint('session', __name__)

def parse_user_id():
    token = None
    if 'Authorization' in request.headers:
        auth_header = request.headers['Authorization']
        parts = auth_header.split(" ")
        if len(parts) == 2 and parts[0] == 'Bearer':
            token = parts[1]
    if token:
        try:
            data = jwt.decode(token, Config.SECRET_KEY, algorithms=[Config.JWT_ALGORITHM])
            return data.get('user_id')
        except Exception:
            pass
    return None

@session_bp.route('/save-session', methods=['POST'])
def save_session():
    """Manual analytics save endpoint directly saving into posture_ai.history and posture_ai.reports."""
    data = request.get_json() or {}
    
    duration = data.get('duration', 0)
    score = data.get('score', 100)
    bad_posture_count = data.get('bad_posture_count', 0)
    user_id = parse_user_id() or data.get('user_id') or getattr(g, 'user_id', 'user_demo_001')
    problems_detected = data.get('problems_detected', [])

    try:
        session_id = data.get('session_id') or data.get('id') or f"rpt_{str(uuid.uuid4())[:8]}"
        created_at = data.get('date') or datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        session = SessionModel(
            session_id=session_id,
            user_id=user_id,
            date=created_at,
            duration=int(duration),
            score=int(score),
            bad_posture_count=int(bad_posture_count),
            average_neck_angle=float(data.get('average_neck_angle', 0.0))
        )
        
        session_dict = session.to_dict()
        session_dict['_id'] = session_id
        session_dict['id'] = session_id
        session_dict['problems_detected'] = problems_detected
        
        # Save to both collections for persistence
        db.history.replace_one({'_id': session_id}, session_dict, upsert=True)
        db.reports.replace_one({'_id': session_id}, session_dict, upsert=True)

        return jsonify({
            'message': 'Session analytics recorded successfully.',
            'session_id': session_id,
            'session': session_dict
        }), 201
    except Exception as e:
        return jsonify({'message': f'Database write failure: {str(e)}'}), 500

@session_bp.route('/sessions/<user_id>', methods=['GET'])
def get_user_sessions(user_id):
    """
    Returns all logged posture session summaries of a user from posture_ai.history.
    """
    token_user_id = parse_user_id()
    target_user_id = token_user_id or user_id

    try:
        # Search by user_id or return all history if demo/general search
        cursor = list(db.history.find({'user_id': target_user_id}))
        if not cursor and target_user_id != user_id:
            cursor = list(db.history.find({'user_id': user_id}))
        if not cursor:
            cursor = list(db.history.find({}))
        
        sessions_list = []
        for doc in cursor:
            if '_id' in doc and not isinstance(doc['_id'], str):
                doc['_id'] = str(doc['_id'])
            if 'id' not in doc:
                doc['id'] = doc.get('session_id', doc['_id'])
            sessions_list.append(doc)
            
        sessions_list.sort(key=lambda s: str(s.get('date', '')), reverse=True)

        return jsonify({'sessions': sessions_list}), 200
    except Exception as e:
        return jsonify({'message': f'Database query error: {str(e)}'}), 500


