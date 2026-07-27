from datetime import datetime

class SessionModel:
    def __init__(self, session_id, user_id, date=None, duration=0, score=100, bad_posture_count=0, average_neck_angle=0.0):
        self.session_id = session_id
        self.user_id = user_id
        self.date = date or datetime.now().strftime("%Y-%m-%d")
        self.duration = duration  # in seconds
        self.score = score        # percentage 0-100 (good posture percentage)
        self.good_posture_pct = score
        self.bad_posture_pct = 100 - score
        self.bad_posture_count = bad_posture_count
        self.average_neck_angle = average_neck_angle

    def to_dict(self):
        """Convert session representation into dictionary format suitable for Firestore."""
        # Calculate qualitative session rating
        status = "Good"
        if self.score < 60:
            status = "Poor"
        elif self.score < 80:
            status = "Fair"

        # Format human-readable duration
        minutes = self.duration // 60
        seconds = self.duration % 60
        duration_str = f"{minutes:02d}:{seconds:02d}"

        return {
            'session_id': self.session_id,
            'user_id': self.user_id,
            'date': self.date,
            'duration': self.duration,
            'duration_str': duration_str,
            'score': self.score,
            'good_posture_pct': self.good_posture_pct,
            'bad_posture_pct': self.bad_posture_pct,
            'bad_posture_count': self.bad_posture_count,
            'average_neck_angle': round(self.average_neck_angle, 1),
            'status': status
        }

    @staticmethod
    def from_dict(data):
        """Instantiate session model from firestore dictionary data."""
        if not data:
            return None
        return SessionModel(
            session_id=data.get('session_id'),
            user_id=data.get('user_id'),
            date=data.get('date'),
            duration=data.get('duration', 0),
            score=data.get('score', 100),
            bad_posture_count=data.get('bad_posture_count', 0),
            average_neck_angle=data.get('average_neck_angle', 0.0)
        )
