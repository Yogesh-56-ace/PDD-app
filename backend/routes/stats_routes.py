from flask import Blueprint, jsonify, g
from services.analytics_service import AnalyticsService
from middleware.auth_middleware import token_required
from database.mongodb import db
from datetime import datetime, timedelta

stats_bp = Blueprint('stats', __name__)

@stats_bp.route('/stats/<user_id>', methods=['GET'])
@token_required
def get_stats(user_id):
    """
    Retrieves historical weekly analytics, overall score ratings,
    and cumulative sitting corrections totals.
    """
    if g.user_id != user_id:
        return jsonify({'message': 'Access Denied: Token ownership mismatch!'}), 403

    try:
        stats = AnalyticsService.get_user_stats(user_id)
        return jsonify({'stats': stats}), 200
    except Exception as e:
        return jsonify({'message': f'Analytics server failure: {str(e)}'}), 500

@stats_bp.route('/dashboard/<user_id>', methods=['GET'])
@token_required
def get_dashboard_data(user_id):
    """
    Aggregates dashboard metrics from posture_ai.users and posture_ai.history.
    """
    if g.user_id != user_id:
        return jsonify({'message': 'Access Denied: Token ownership mismatch!'}), 403

    try:
        # 1. Fetch user profile details
        user_doc = db.users.find_one({'_id': user_id}) or db.users.find_one({'user_id': user_id}) or {}
        username = user_doc.get('name', 'User')

        # 2. Query today's and yesterday's sessions from posture_ai.history
        today_str = datetime.now().strftime("%Y-%m-%d")
        yesterday_str = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")

        cursor = db.history.find({'user_id': user_id})
        
        today_sessions = []
        yesterday_sessions = []
        
        for data in cursor:
            s_date = data.get('date')
            if s_date == today_str:
                today_sessions.append(data)
            elif s_date == yesterday_str:
                yesterday_sessions.append(data)

        # 3. Calculate today's aggregates
        today_duration = sum(s.get('duration', 0) for s in today_sessions)
        today_corrections = sum(s.get('bad_posture_count', 0) for s in today_sessions)
        
        if today_sessions:
            today_avg_score = int(sum(s.get('score', 100) for s in today_sessions) / len(today_sessions))
        else:
            today_avg_score = 100

        # 4. Calculate daily progress percentage
        if yesterday_sessions:
            yesterday_avg_score = int(sum(s.get('score', 100) for s in yesterday_sessions) / len(yesterday_sessions))
        else:
            yesterday_avg_score = 80
            
        progress_diff = today_avg_score - yesterday_avg_score
        daily_progress_str = f"{progress_diff:+.1f}%" if progress_diff != 0 else "+0%"

        # 5. Fetch weekly progress chart trend
        weekly_stats = AnalyticsService.get_user_stats(user_id)
        
        hours = today_duration // 3600
        minutes = (today_duration % 3600) // 60
        duration_str = f"{hours}h {minutes}m" if hours > 0 else f"{minutes}m"
        if today_duration == 0:
            duration_str = "0m"

        return jsonify({
            'username': username,
            'today_duration': today_duration,
            'today_duration_str': duration_str,
            'today_score': today_avg_score,
            'today_corrections': today_corrections,
            'daily_progress': daily_progress_str,
            'weekly_progress': weekly_stats.get('weekly_scores', [80, 85, 90, 85, 88, 92, 94])
        }), 200

    except Exception as e:
        return jsonify({'message': f'Dashboard compilation error: {str(e)}'}), 500

