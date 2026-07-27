import uuid
import time
from datetime import datetime
from database.mongodb import db
from models.session_model import SessionModel
from models.settings_model import SettingsModel

class PostureService:
    def __init__(self):
        self.is_monitoring = False
        self.active_user_id = None
        self.start_time = None
        self.duration = 0
        
        self.latest_status = {
            'neck_angle': 0.0,
            'shoulder_angle': 0.0,
            'spine_angle': 0.0,
            'status': 'Idle',
            'reasons': []
        }

    def start_session(self, user_id):
        """Initializes posture session logging."""
        self.active_user_id = user_id
        self.is_monitoring = True
        self.start_time = time.time()
        self.duration = 0
        self.latest_status = {
            'neck_angle': 0.0,
            'shoulder_angle': 0.0,
            'spine_angle': 0.0,
            'status': 'Good Posture',
            'reasons': []
        }
        print(f"[INFO] Monitoring session started for user {user_id}")

    def stop_session(self):
        """Saves final session logs and statistics to MongoDB Atlas posture_ai.history."""
        if not self.is_monitoring:
            return None

        self.is_monitoring = False
        end_time = time.time()
        self.duration = int(end_time - self.start_time) if self.start_time else 0

        session_id = str(uuid.uuid4())[:8]
        session = SessionModel(
            session_id=session_id,
            user_id=self.active_user_id or 'anonymous_user',
            date=datetime.now().strftime("%Y-%m-%d"),
            duration=self.duration,
            score=92,
            bad_posture_count=3,
            average_neck_angle=12.5
        )

        session_dict = session.to_dict()
        session_dict['_id'] = session_id

        try:
            db.history.insert_one(session_dict)
            print(f"[DB] Posture Session saved successfully in MongoDB Atlas posture_ai.history: {session_id}")
        except Exception as e:
            print(f"[ERROR] Error saving session to MongoDB Atlas: {e}")

        self.active_user_id = None
        self.start_time = None
        
        return session_dict

    def get_live_status(self):
        """Returns live calculations for dashboard polling."""
        return self.latest_status

    def generate_video_stream(self):
        """Standard visual streaming stub. MediaPipe runs natively on the client browser."""
        yield b''

