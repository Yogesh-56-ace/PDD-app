from flask import request, jsonify, g
from functools import wraps
import jwt
from config import Config

def token_required(f):
    """
    Decorator to protect Flask endpoints using JWT Authorization headers.
    Expects header format: Authorization: Bearer <JWT_TOKEN>
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Look up authorization header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            parts = auth_header.split(" ")
            if len(parts) == 2 and parts[0] == 'Bearer':
                token = parts[1]

        if not token:
            return jsonify({'message': 'Authorization token is missing!'}), 401

        try:
            # Decode JWT claims using signature key
            data = jwt.decode(token, Config.SECRET_KEY, algorithms=[Config.JWT_ALGORITHM])
            
            # Inject context globally for logging
            g.user_id = data['user_id']
            g.email = data['email']
            
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Authorization token has expired. Please log in again.'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Invalid authorization token!'}), 401

        return f(*args, **kwargs)

    return decorated
