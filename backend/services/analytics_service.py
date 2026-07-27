from database.mongodb import db
from datetime import datetime

class AnalyticsService:
    @staticmethod
    def get_user_stats(user_id):
        """
        Retrieves user historical session metrics directly from MongoDB Atlas posture_ai.history
        and compiles dashboard aggregates.
        """
        try:
            cursor = list(db.history.find({'user_id': user_id}))
            
            total_sessions = len(cursor)
            if total_sessions == 0:
                return {
                    'total_sessions': 0,
                    'total_duration_mins': 0,
                    'avg_score': 0,
                    'total_corrections': 0,
                    'weekly_scores': [0, 0, 0, 0, 0, 0, 0]
                }

            total_duration = 0
            total_score = 0
            total_corrections = 0
            
            weekly_totals = {0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: []}

            for data in cursor:
                total_duration += data.get('duration', 0)
                total_score += data.get('score', 100)
                total_corrections += data.get('bad_posture_count', 0)
                
                date_str = data.get('date', '')
                try:
                    dt = datetime.strptime(date_str, "%Y-%m-%d")
                    day_index = dt.weekday()
                    weekly_totals[day_index].append(data.get('score', 100))
                except Exception:
                    pass

            avg_score = int(total_score / total_sessions)
            total_duration_mins = int(total_duration / 60)

            weekly_scores = []
            for i in range(7):
                day_scores = weekly_totals[i]
                if day_scores:
                    weekly_scores.append(int(sum(day_scores) / len(day_scores)))
                else:
                    weekly_scores.append(0)

            return {
                'total_sessions': total_sessions,
                'total_duration_mins': total_duration_mins,
                'avg_score': avg_score,
                'total_corrections': total_corrections,
                'weekly_scores': weekly_scores
            }

        except Exception as e:
            print(f"Error compiling session analytics: {e}")
            return {
                'total_sessions': 0,
                'total_duration_mins': 0,
                'avg_score': 0,
                'total_corrections': 0,
                'weekly_scores': [0, 0, 0, 0, 0, 0, 0]
            }

