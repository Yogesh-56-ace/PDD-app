import bcrypt
import jwt
from datetime import datetime, timedelta
from config import Config

class AuthService:
    @staticmethod
    def hash_password(password):
        """Hashes a raw password string using Bcrypt with a work factor salt."""
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
        return hashed.decode('utf-8')

    @staticmethod
    def check_password(password, hashed_password):
        """Verifies a raw password against its stored Bcrypt hash."""
        try:
            return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))
        except Exception:
            return False

    @staticmethod
    def generate_token(user_id, email):
        """Generates a secure, cryptographically signed JWT token expiring in 24 hours."""
        try:
            payload = {
                'exp': datetime.utcnow() + timedelta(hours=Config.JWT_EXPIRATION_HOURS),
                'iat': datetime.utcnow(),
                'user_id': user_id,
                'email': email
            }
            return jwt.encode(
                payload,
                Config.SECRET_KEY,
                algorithm=Config.JWT_ALGORITHM
            )
        except Exception as e:
            return None

    @staticmethod
    def verify_token(token):
        """Decodes and validates a JWT token signature."""
        try:
            payload = jwt.decode(
                token,
                Config.SECRET_KEY,
                algorithms=[Config.JWT_ALGORITHM]
            )
            return payload
        except jwt.ExpiredSignatureError:
            return None # Token expired
        except jwt.InvalidTokenError:
            return None # Token invalid
