class SettingsModel:
    def __init__(self, user_id, audio_alert=True, sensitivity='medium', reminder_interval=15):
        self.user_id = user_id
        self.audio_alert = audio_alert
        self.sensitivity = sensitivity  # 'low', 'medium', 'high'
        self.reminder_interval = reminder_interval  # in minutes

    def to_dict(self):
        """Convert settings representation into dictionary format suitable for Firestore."""
        return {
            'user_id': self.user_id,
            'audio_alert': self.audio_alert,
            'sensitivity': self.sensitivity,
            'reminder_interval': self.reminder_interval
        }

    @staticmethod
    def from_dict(data, user_id):
        """Instantiate settings model from firestore dictionary data, falling back to defaults if empty."""
        if not data:
            return SettingsModel(user_id=user_id)
        return SettingsModel(
            user_id=user_id,
            audio_alert=data.get('audio_alert', True),
            sensitivity=data.get('sensitivity', 'medium'),
            reminder_interval=data.get('reminder_interval', 15)
        )
