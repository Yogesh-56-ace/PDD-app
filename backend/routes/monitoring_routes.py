from flask import Blueprint, Response, request, jsonify
from services.posture_service import PostureService
import jwt
from config import Config

monitoring_bp = Blueprint('monitoring', __name__)
posture_service = PostureService()

@monitoring_bp.route('/start', methods=['POST'])
def start_monitoring():
    """Initializes the webcam posture tracking session."""
    user_id = 'anonymous_user'
    
    # Optional authorization injection if token is passed in header
    auth_header = request.headers.get('Authorization')
    if auth_header and auth_header.startswith('Bearer '):
        try:
            token = auth_header.split(' ')[1]
            data = jwt.decode(token, Config.SECRET_KEY, algorithms=[Config.JWT_ALGORITHM])
            user_id = data['user_id']
        except Exception:
            pass

    posture_service.start_session(user_id)
    return jsonify({'status': 'Session tracking started', 'user_id': user_id}), 200

@monitoring_bp.route('/stop', methods=['POST'])
def stop_monitoring():
    """Finalizes active webcam tracking, counts scores, and stores metrics in Firestore."""
    session_data = posture_service.stop_session()
    if not session_data:
        return jsonify({'message': 'No active posture monitoring session to finalize.'}), 400
    
    return jsonify({
        'status': 'Session monitoring finalized successfully',
        'session': session_data
    }), 200

@monitoring_bp.route('/video_feed', methods=['GET'])
def video_feed():
    """
    Returns the real-time webcam frame processing feed as a continuous
    MJPEG multipart boundary source stream. Displays drawn skeleton overlay visually.
    """
    # Ensure posture monitoring is marked active
    if not posture_service.is_monitoring:
        # Fallback start if user navigates straight to MJPEG URL
        posture_service.start_session('anonymous_user')

    return Response(
        posture_service.generate_video_stream(),
        mimetype='multipart/x-mixed-replace; boundary=frame'
    )

@monitoring_bp.route('/status', methods=['GET'])
def live_status():
    """
    Returns live calculations of computed joint angles and warning triggers
    so that frontend dashboards can poll them dynamically in real-time.
    """
    return jsonify(posture_service.get_live_status()), 200
