from database.mongodb import db
from datetime import datetime, timedelta

class AnalyticsService:
    @staticmethod
    def get_user_stats(user_id, timeframe='this_week', start_date=None, end_date=None):
        """
        Retrieves user historical session metrics directly from MongoDB Atlas posture_ai.history and reports,
        filters by timeframe (today, this_week, this_month, custom, all), and compiles accurate stats.
        """
        try:
            now = datetime.now()
            
            # Search by user_id or retrieve all sessions if user_id is demo/all
            cursor = list(db.history.find({'user_id': user_id})) or list(db.reports.find({'user_id': user_id}))
            if not cursor:
                cursor = list(db.history.find({})) or list(db.reports.find({}))

            # Deduplicate sessions by ID
            seen_ids = set()
            unique_sessions = []
            for item in cursor:
                item_id = item.get('id') or item.get('session_id') or item.get('_id')
                if item_id and str(item_id) not in seen_ids:
                    seen_ids.add(str(item_id))
                    unique_sessions.append(item)

            # Helper to parse date string or timestamp
            def parse_item_date(item):
                date_val = item.get('date', '')
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
                created_at = item.get('created_at')
                if isinstance(created_at, datetime):
                    return created_at
                return now

            current_items = []
            prev_items = []

            # Custom Date Range Parsing
            parsed_start = None
            parsed_end = None
            if timeframe == 'custom' and start_date:
                try:
                    parsed_start = datetime.strptime(start_date, "%Y-%m-%d").replace(hour=0, minute=0, second=0)
                except Exception:
                    pass
            if timeframe == 'custom' and end_date:
                try:
                    parsed_end = datetime.strptime(end_date, "%Y-%m-%d").replace(hour=23, minute=59, second=59)
                except Exception:
                    pass

            for item in unique_sessions:
                dt = parse_item_date(item)

                if timeframe == 'today':
                    if dt.date() == now.date():
                        current_items.append(item)
                    elif dt.date() == (now - timedelta(days=1)).date():
                        prev_items.append(item)
                elif timeframe == 'this_month':
                    if dt.year == now.year and dt.month == now.month:
                        current_items.append(item)
                    elif dt.year == (now.year if now.month > 1 else now.year - 1) and dt.month == (now.month - 1 or 12):
                        prev_items.append(item)
                elif timeframe == 'custom':
                    match = True
                    if parsed_start and dt < parsed_start:
                        match = False
                    if parsed_end and dt > parsed_end:
                        match = False
                    if match:
                        current_items.append(item)
                elif timeframe == 'all':
                    current_items.append(item)
                else:
                    # Default: this_week (Monday to Sunday)
                    start_of_week = now - timedelta(days=now.weekday())
                    start_of_week = start_of_week.replace(hour=0, minute=0, second=0, microsecond=0)
                    start_of_prev_week = start_of_week - timedelta(days=7)
                    end_of_prev_week = start_of_week - timedelta(seconds=1)

                    if dt >= start_of_week:
                        current_items.append(item)
                    elif start_of_prev_week <= dt <= end_of_prev_week:
                        prev_items.append(item)

            target_list = current_items
            total_sessions = len(target_list)

            if total_sessions == 0:
                return {
                    'total_sessions': 0,
                    'total_duration_mins': 0,
                    'total_duration_str': '0m',
                    'avg_score': 0,
                    'improvement_pct': 0.0,
                    'is_improvement': True,
                    'total_corrections': 0,
                    'weekly_scores': [0, 0, 0, 0, 0, 0, 0],
                    'time_distribution': {
                        'good_pct': 0.0,
                        'mild_pct': 0.0,
                        'severe_pct': 0.0
                    }
                }

            total_duration_sec = 0
            total_score = 0
            total_corrections = 0
            good_count = 0
            mild_count = 0
            severe_count = 0

            weekly_totals = {0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: []}

            for data in target_list:
                dur = data.get('duration', 0)
                if not dur and data.get('duration_str'):
                    # Parse duration string if int is missing
                    d_str = str(data.get('duration_str'))
                    import re
                    hm = re.search(r'(\d+)\s*h', d_str)
                    mm = re.search(r'(\d+)\s*m', d_str)
                    sm = re.search(r'(\d+)\s*s', d_str)
                    dur = 0
                    if hm: dur += int(hm.group(1)) * 3600
                    if mm: dur += int(mm.group(1)) * 60
                    if sm: dur += int(sm.group(1))
                if not dur:
                    dur = 60 # Default 1 min for static scan reports

                total_duration_sec += dur

                raw_score = data.get('score') if data.get('score') is not None else data.get('overall_score', 85)
                try:
                    score_val = int(float(raw_score))
                except Exception:
                    score_val = 85
                total_score += score_val

                # Count corrections/alerts
                corrections = data.get('bad_posture_count')
                if corrections is None:
                    corrections = data.get('alert_count')
                if corrections is None:
                    problems = data.get('problems_detected', []) or data.get('problems', [])
                    corrections = len(problems) if isinstance(problems, list) else 0
                total_corrections += int(corrections)

                # Classify score quality for time distribution
                if score_val >= 80:
                    good_count += 1
                elif score_val >= 60:
                    mild_count += 1
                else:
                    severe_count += 1

                dt = parse_item_date(data)
                day_index = dt.weekday()
                weekly_totals[day_index].append(score_val)

            avg_score = int(total_score / total_sessions)

            # Format total duration as hours and minutes
            hours = total_duration_sec // 3600
            mins = (total_duration_sec % 3600) // 60
            total_duration_str = f"{hours}h {mins}m" if hours > 0 else f"{mins}m"
            if total_duration_sec == 0:
                total_duration_str = "0m"

            # Calculate improvement vs previous period
            if prev_items:
                prev_total_score = sum(int(float(p.get('score') or p.get('overall_score', 85))) for p in prev_items)
                prev_avg = int(prev_total_score / len(prev_items))
                delta = round(avg_score - prev_avg, 1)
            else:
                delta = 0.0

            is_improvement = delta >= 0
            improvement_pct = abs(delta)

            # Weekly daily averages Mon-Sun
            weekly_scores = []
            for i in range(7):
                day_scores = weekly_totals[i]
                if day_scores:
                    weekly_scores.append(int(sum(day_scores) / len(day_scores)))
                else:
                    weekly_scores.append(0)

            good_pct = round(good_count / total_sessions, 2)
            mild_pct = round(mild_count / total_sessions, 2)
            severe_pct = round(severe_count / total_sessions, 2)

            return {
                'total_sessions': total_sessions,
                'total_duration_mins': total_duration_sec // 60,
                'total_duration_str': total_duration_str,
                'avg_score': avg_score,
                'improvement_pct': improvement_pct,
                'is_improvement': is_improvement,
                'total_corrections': total_corrections,
                'weekly_scores': weekly_scores,
                'time_distribution': {
                    'good_pct': good_pct,
                    'mild_pct': mild_pct,
                    'severe_pct': severe_pct
                }
            }

        except Exception as e:
            print(f"Error compiling session analytics: {e}")
            return {
                'total_sessions': 0,
                'total_duration_mins': 0,
                'total_duration_str': '0m',
                'avg_score': 0,
                'improvement_pct': 0.0,
                'is_improvement': True,
                'total_corrections': 0,
                'weekly_scores': [0, 0, 0, 0, 0, 0, 0],
                'time_distribution': {
                    'good_pct': 0.0,
                    'mild_pct': 0.0,
                    'severe_pct': 0.0
                }
            }

