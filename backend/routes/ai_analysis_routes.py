from flask import Blueprint, request, jsonify
from services.ai_posture_engine import AIPostureEngine
import jwt
from config import Config

ai_analysis_bp = Blueprint('ai_analysis', __name__)
engine = AIPostureEngine()

def parse_token_user_id():
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

@ai_analysis_bp.route('/upload-image', methods=['POST'])
def upload_image_analysis():
    """Endpoint for Image Posture Upload & MediaPipe + Gemini Analysis."""
    file = request.files.get('file')
    user_id = parse_token_user_id()
    
    report = engine.analyze_pose(media_type="image", file_source=file, user_id=user_id)
    return jsonify({
        "status": "success",
        "message": "Image posture analysis completed via Cloudinary, MediaPipe 33 Landmarks & Gemini AI",
        "report": report
    }), 200

@ai_analysis_bp.route('/upload-video', methods=['POST'])
def upload_video_analysis():
    """Endpoint for Video Posture Upload & MediaPipe Telemetry Analysis."""
    file = request.files.get('file')
    user_id = parse_token_user_id()

    report = engine.analyze_pose(media_type="video", file_source=file, user_id=user_id)
    return jsonify({
        "status": "success",
        "message": "Video posture analysis completed across keyframes",
        "report": report
    }), 200

@ai_analysis_bp.route('/live-frame', methods=['POST'])
def live_frame_analysis():
    """Endpoint for Live Camera Posture Snapshot Analysis."""
    data = request.get_json() or {}
    user_id = parse_token_user_id() or data.get('user_id')
    report = engine.analyze_pose(media_type="live", custom_data=data, user_id=user_id)
    return jsonify({
        "status": "success",
        "message": "Live camera posture snapshot analyzed",
        "report": report
    }), 200

@ai_analysis_bp.route('/history', methods=['GET'])
def get_analysis_history():
    """Returns list of previous posture AI analysis reports."""
    reports = engine.get_all_reports()
    return jsonify({
        "status": "success",
        "count": len(reports),
        "reports": reports
    }), 200

@ai_analysis_bp.route('/report/<report_id>', methods=['GET'])
def get_report_details(report_id):
    """Returns complete saved report by ID."""
    report = engine.get_report_by_id(report_id)
    return jsonify({
        "status": "success",
        "report": report
    }), 200

@ai_analysis_bp.route('/delete/<report_id>', methods=['DELETE', 'POST'])
def delete_report(report_id):
    """Deletes a saved report by ID."""
    success = engine.delete_report(report_id)
    return jsonify({
        "status": "success" if success else "failed",
        "message": f"Report {report_id} deleted successfully."
    }), 200
