from flask import Blueprint, jsonify, g, request
from services.analytics_service import AnalyticsService
from middleware.auth_middleware import token_required
from database.mongodb import db
from datetime import datetime, timedelta

stats_bp = Blueprint('stats', __name__)

@stats_bp.route('/stats/weekly', methods=['GET'])
@stats_bp.route('/stats', methods=['GET'])
@token_required
def get_current_user_stats():
    return get_stats(g.user_id)

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
        timeframe = request.args.get('timeframe', 'this_week')
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        stats = AnalyticsService.get_user_stats(user_id, timeframe, start_date=start_date, end_date=end_date)
        return jsonify({'stats': stats}), 200
    except Exception as e:
        return jsonify({'message': f'Analytics server failure: {str(e)}'}), 500

@stats_bp.route('/dashboard', methods=['GET'])
@token_required
def get_current_user_dashboard():
    return get_dashboard_data(g.user_id)

@stats_bp.route('/dashboard/<user_id>', methods=['GET'])
@token_required
def get_dashboard_data(user_id):
    """
    Aggregates real-time dashboard metrics from posture_ai.users, posture_ai.history, and posture_ai.reports.
    Handles empty states gracefully when no sessions exist.
    """
    if g.user_id != user_id:
        return jsonify({'message': 'Access Denied: Token ownership mismatch!'}), 403

    try:
        # 1. Fetch user profile details
        user_doc = db.users.find_one({'_id': user_id}) or db.users.find_one({'user_id': user_id}) or {}
        username = user_doc.get('name', 'User')

        # 2. Query all sessions from posture_ai.history and posture_ai.reports
        cursor = list(db.history.find({'user_id': user_id})) + list(db.reports.find({'user_id': user_id}))
        
        # Deduplicate sessions by ID
        seen_ids = set()
        unique_sessions = []
        for data in cursor:
            sid = str(data.get('id') or data.get('session_id') or data.get('_id', ''))
            if sid and sid not in seen_ids:
                seen_ids.add(sid)
                unique_sessions.append(data)

        # Handle explicit Empty State if no sessions exist
        if not unique_sessions:
            return jsonify({
                'username': username,
                'has_sessions': False,
                'total_sessions': 0,
                'today_duration': 0,
                'today_duration_str': '0m',
                'total_duration_str': '0m',
                'today_score': 0,
                'today_corrections': 0,
                'total_corrections': 0,
                'latest_score': None,
                'latest_status': 'No Session Data',
                'latest_title': 'No Scans Yet',
                'latest_desc': 'Complete your first AI live camera tracking session or upload a posture photo to start tracking.',
                'spinal_risk': 'N/A',
                'emoji': '📊',
                'ai_insight': 'Take your first AI posture scan or start live webcam tracking to unlock personalized AI ergonomic insights and body alignment analysis.',
                'recommended_stretch': 'Start a 2-minute live camera tracking session.',
                'daily_progress': '+0%',
                'weekly_progress': [0, 0, 0, 0, 0, 0, 0]
            }), 200

        # Helper to parse session date
        now = datetime.now()
        today_str = now.strftime("%Y-%m-%d")
        yesterday_str = (now - timedelta(days=1)).strftime("%Y-%m-%d")

        def parse_session_dt(item):
            date_val = item.get('date') or item.get('created_at')
            if isinstance(date_val, datetime):
                return date_val
            if isinstance(date_val, str) and date_val:
                for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M:%S.%f"):
                    try:
                        return datetime.strptime(date_val, fmt)
                    except Exception:
                        pass
                try:
                    return datetime.strptime(date_val.split('T')[0], "%Y-%m-%d")
                except Exception:
                    pass
            return datetime.min

        # Sort sessions descending by date
        unique_sessions.sort(key=parse_session_dt, reverse=True)

        today_sessions = []
        yesterday_sessions = []

        total_duration_sec = 0
        total_corrections_count = 0

        for s in unique_sessions:
            s_dt = parse_session_dt(s)
            s_date_str = s_dt.strftime("%Y-%m-%d") if s_dt != datetime.min else ""
            
            dur = s.get('duration', 0)
            if isinstance(dur, (int, float)):
                total_duration_sec += int(dur)
            
            # Count corrections/alerts
            corrections = s.get('bad_posture_count')
            if corrections is None:
                corrections = s.get('alert_count')
            if corrections is None:
                problems = s.get('problems_detected', []) or s.get('problems', [])
                corrections = len(problems) if isinstance(problems, list) else 0
            
            try:
                total_corrections_count += int(corrections)
            except Exception:
                pass

            if s_date_str == today_str:
                today_sessions.append(s)
            elif s_date_str == yesterday_str:
                yesterday_sessions.append(s)

        # 3. Calculate today's aggregates
        today_duration = sum(int(s.get('duration', 0)) for s in today_sessions)
        today_corrections = 0
        for s in today_sessions:
            c = s.get('bad_posture_count') or s.get('alert_count') or len(s.get('problems_detected', []))
            try:
                today_corrections += int(c)
            except Exception:
                pass

        if today_sessions:
            today_avg_score = int(sum(int(float(s.get('score') or s.get('overall_score', 85))) for s in today_sessions) / len(today_sessions))
        else:
            # Fallback to latest session score or overall average score if no today session
            all_scores = [int(float(s.get('score') or s.get('overall_score', 85))) for s in unique_sessions]
            today_avg_score = int(sum(all_scores) / len(all_scores)) if all_scores else 85

        # Format today duration as hours and minutes
        t_hours = today_duration // 3600
        t_mins = (today_duration % 3600) // 60
        today_duration_str = f"{t_hours}h {t_mins}m" if t_hours > 0 else f"{t_mins}m"
        if today_duration == 0:
            today_duration_str = "0m"

        # Format total duration
        tot_hours = total_duration_sec // 3600
        tot_mins = (total_duration_sec % 3600) // 60
        total_duration_str = f"{tot_hours}h {tot_mins}m" if tot_hours > 0 else f"{tot_mins}m"
        if total_duration_sec == 0:
            total_duration_str = "0m"

        # 4. Calculate daily progress percentage vs yesterday
        if yesterday_sessions:
            yesterday_avg_score = int(sum(int(float(s.get('score') or s.get('overall_score', 85))) for s in yesterday_sessions) / len(yesterday_sessions))
            progress_diff = today_avg_score - yesterday_avg_score
            daily_progress_str = f"{progress_diff:+.1f}%" if progress_diff != 0 else "+0%"
        else:
            daily_progress_str = "+0%"

        # 5. Extract latest session/report for Good Posture & AI Insight cards
        latest_session = unique_sessions[0]
        latest_score = int(float(latest_session.get('score') or latest_session.get('overall_score', 85)))

        if latest_score >= 85:
            latest_status = 'Good Posture'
            latest_title = 'Aligned & Healthy Spine'
            latest_desc = f"You've maintained excellent spinal posture for {latest_score}% of your latest posture analysis."
            spinal_risk = 'Low Risk'
            emoji = '😊'
        elif latest_score >= 70:
            latest_status = 'Needs Attention'
            latest_title = 'Slouching Detected'
            latest_desc = f"Your latest posture score was {latest_score}%. Sit upright and maintain shoulder balance."
            spinal_risk = 'Moderate Risk'
            emoji = '😐'
        else:
            latest_status = 'Poor Posture'
            latest_title = 'Severe Posture Stress'
            latest_desc = f"Warning: Your latest posture score dropped to {latest_score}%. Take a stretch break immediately."
            spinal_risk = 'High Risk'
            emoji = '🥵'

        # Generate dynamic AI insight from latest report
        ai_insight = latest_session.get('ai_explanation')
        if not ai_insight:
            recs = latest_session.get('recommendations', [])
            if isinstance(recs, list) and recs:
                ai_insight = recs[0]
            else:
                probs = latest_session.get('problems_detected', [])
                if isinstance(probs, list) and probs:
                    ai_insight = f"Detected posture concern: {probs[0]}. Maintain shoulder alignment and keep screen at eye level."
                else:
                    ai_insight = f"Your latest posture score is {latest_score}%. Keep maintaining ear-over-shoulder alignment while working."

        # Extract recommended stretch from latest report
        exercises = latest_session.get('suggested_exercises', [])
        if isinstance(exercises, list) and exercises and isinstance(exercises[0], dict):
            ex = exercises[0]
            title = ex.get('title', 'Chin Tucks')
            dur = ex.get('duration', '3 sets x 10 reps')
            desc = ex.get('description', '')
            recommended_stretch = f"{title} ({dur}): {desc}" if desc else f"{title} ({dur})"
        else:
            recommended_stretch = "Perform 5 Chin Tucks during work breaks to relieve neck strain."

        # 6. Fetch weekly progress chart trend
        weekly_stats = AnalyticsService.get_user_stats(user_id)
        weekly_progress = weekly_stats.get('weekly_scores', [0, 0, 0, 0, 0, 0, 0])

        return jsonify({
            'username': username,
            'has_sessions': True,
            'total_sessions': len(unique_sessions),
            'today_duration': today_duration,
            'today_duration_str': today_duration_str,
            'total_duration_str': total_duration_str,
            'today_score': today_avg_score,
            'today_corrections': today_corrections,
            'total_corrections': total_corrections_count,
            'latest_score': latest_score,
            'latest_status': latest_status,
            'latest_title': latest_title,
            'latest_desc': latest_desc,
            'spinal_risk': spinal_risk,
            'emoji': emoji,
            'ai_insight': ai_insight,
            'recommended_stretch': recommended_stretch,
            'daily_progress': daily_progress_str,
            'weekly_progress': weekly_progress
        }), 200

    except Exception as e:
        return jsonify({'message': f'Dashboard compilation error: {str(e)}'}), 500

