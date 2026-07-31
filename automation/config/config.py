import os

class AutomationConfig:
    # BASE_URL resolved dynamically from environment or defaults to LIVE GitHub Pages deployment URL
    # MANDATORY: BASE_URL must be configurable via environment variable
    BASE_URL = os.environ.get(
        'BASE_URL',
        'https://Yogesh-56-ace.github.io/PDD-app/'
    ).rstrip('/') + '/'

    LOCAL_FALLBACK_URL = 'http://localhost:3000/'
    
    HEADLESS = os.environ.get('HEADLESS', 'true').lower() == 'true'
    IMPLICIT_WAIT = 10
    EXPLICIT_WAIT = 15
    RETRY_COUNT = 2

    # Artifact Directory Paths
    REPORTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'reports'))
    SCREENSHOTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'screenshots'))
    LOGS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'logs'))
