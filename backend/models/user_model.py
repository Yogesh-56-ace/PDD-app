class UserModel:
    def __init__(self, user_id, name, email, password_hash=None, onboarding_completed=False, age=None, gender=None, profile_image=None):
        self.user_id = user_id
        self.name = name
        self.email = email
        self.password_hash = password_hash
        self.onboarding_completed = onboarding_completed
        self.age = age
        self.gender = gender
        self.profile_image = profile_image

    def to_dict(self):
        """Convert model representation into dictionary format suitable for Firestore."""
        data = {
            'user_id': self.user_id,
            'name': self.name,
            'email': self.email,
            'onboarding_completed': self.onboarding_completed,
            'age': self.age,
            'gender': self.gender,
            'profile_image': self.profile_image
        }
        if self.password_hash:
            data['password_hash'] = self.password_hash
        return data

    @staticmethod
    def from_dict(data):
        """Instantiate user model from firestore dictionary data."""
        if not data:
            return None
        return UserModel(
            user_id=data.get('user_id'),
            name=data.get('name'),
            email=data.get('email'),
            password_hash=data.get('password_hash'),
            onboarding_completed=data.get('onboarding_completed', False),
            age=data.get('age'),
            gender=data.get('gender'),
            profile_image=data.get('profile_image')
        )
