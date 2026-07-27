import os
import sys
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env'))

# Ensure backend directory is in python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, jsonify, render_template
from flask_cors import CORS
from config import Config

# Import blueprints
from routes.auth_routes import auth_bp
from routes.monitoring_routes import monitoring_bp
from routes.session_routes import session_bp
from routes.stats_routes import stats_bp
from routes.settings_routes import settings_bp
from routes.user_routes import user_bp
from routes.alert_routes import alert_bp
from routes.ai_analysis_routes import ai_analysis_bp

def create_app():
    """Application factory initializing blueprints and settings."""
    app = Flask(__name__)
    app.config.from_object(Config)

    # 1. Enable Cross-Origin Resource Sharing (CORS)
    CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

    # 2. Register Blueprints
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(monitoring_bp, url_prefix='/api/monitoring')
    app.register_blueprint(session_bp, url_prefix='/api')
    app.register_blueprint(stats_bp, url_prefix='/api')
    app.register_blueprint(settings_bp, url_prefix='/api')
    app.register_blueprint(user_bp, url_prefix='/api')
    app.register_blueprint(alert_bp, url_prefix='/api')
    app.register_blueprint(ai_analysis_bp, url_prefix='/api')

    # Root Web Dashboard route
    @app.route('/', methods=['GET'])
    def index():
        return render_template('index.html')

    # Serve Mobile Showcase App (exact UI from screenshot)
    @app.route('/showcase', methods=['GET'])
    @app.route('/showcase/<path:path>', methods=['GET'])
    @app.route('/mobile', methods=['GET'])
    @app.route('/mobile/<path:path>', methods=['GET'])
    def serve_mobile_showcase(path=''):
        showcase_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'frontend', 'android', 'app', 'src', 'main', 'assets', 'public'))
        if path != "" and os.path.exists(os.path.join(showcase_dir, path)):
            from flask import send_from_directory
            return send_from_directory(showcase_dir, path)
        else:
            from flask import send_from_directory
            return send_from_directory(showcase_dir, 'index.html')

    # Serve Flutter Web App
    @app.route('/app', methods=['GET'])
    @app.route('/app/<path:path>', methods=['GET'])
    def serve_flutter_app(path=''):
        flutter_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'frontend', 'build', 'web'))
        if path != "" and os.path.exists(os.path.join(flutter_dir, path)):
            from flask import send_from_directory
            return send_from_directory(flutter_dir, path)
        else:
            from flask import send_from_directory
            return send_from_directory(flutter_dir, 'index.html')


    # Simple health check endpoint
    @app.route('/health', methods=['GET'])
    def health_check():
        return jsonify({
            'status': 'healthy',
            'service': 'Posture Fix Pro Modular Backend',
            'engine': 'MediaPipe Pose AI'
        }), 200

    return app


if __name__ == '__main__':
    app = create_app()
    print(f"[INFO] Posture Fix Pro Flask backend launching on http://localhost:{Config.PORT}...")
    app.run(host='0.0.0.0', port=Config.PORT, debug=Config.DEBUG, threaded=True, use_reloader=False)

