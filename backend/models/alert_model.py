from datetime import datetime

class AlertModel:
    def __init__(self, alert_id, user_id, timestamp=None, duration=0, suggestion="", alert_type="Spine"):
        self.alert_id = alert_id
        self.user_id = user_id
        self.timestamp = timestamp or datetime.utcnow().isoformat() + 'Z'
        self.duration = duration  # duration of poor posture in seconds before correction
        self.suggestion = suggestion
        self.alert_type = alert_type  # 'Neck', 'Spine', 'Shoulder'

    def to_dict(self):
        """Convert alert model into a dictionary format suitable for Firestore."""
        return {
            'alert_id': self.alert_id,
            'user_id': self.user_id,
            'timestamp': self.timestamp,
            'duration': self.duration,
            'suggestion': self.suggestion,
            'alert_type': self.alert_type
        }

    @staticmethod
    def from_dict(data):
        """Instantiate alert model from Firestore dictionary data."""
        if not data:
            return None
        return AlertModel(
            alert_id=data.get('alert_id'),
            user_id=data.get('user_id'),
            timestamp=data.get('timestamp'),
            duration=data.get('duration', 0),
            suggestion=data.get('suggestion', ""),
            alert_type=data.get('alert_type', "Spine")
        )
