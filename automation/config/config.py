import os
import sys

class Config:
    # Base URL configured via environment variable BASE_URL
    # MANDATORY: Default strictly targets LIVE GitHub Pages deployment
    DEFAULT_BASE_URL = "https://yogesh-56-ace.github.io/posturefixpro-app/"
    BASE_URL = os.environ.get("BASE_URL", DEFAULT_BASE_URL).rstrip('/') + '/'

    # Driver settings
    HEADLESS = os.environ.get("HEADLESS", "true").lower() in ("true", "1", "yes")
    IMPLICIT_WAIT = int(os.environ.get("IMPLICIT_WAIT", "10"))
    EXPLICIT_WAIT = int(os.environ.get("EXPLICIT_WAIT", "15"))
    PAGE_LOAD_TIMEOUT = int(os.environ.get("PAGE_LOAD_TIMEOUT", "30"))

    # Folder Paths
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    PROJECT_ROOT = os.path.dirname(BASE_DIR)
    
    RESULTS_DIR = os.path.join(PROJECT_ROOT, "Test Results")
    EXCEL_DIR = os.path.join(RESULTS_DIR, "Excel")
    HTML_DIR = os.path.join(RESULTS_DIR, "HTML")
    SCREENSHOTS_DIR = os.path.join(RESULTS_DIR, "Screenshots")
    LOGS_DIR = os.path.join(RESULTS_DIR, "Logs")
    JSON_DIR = os.path.join(RESULTS_DIR, "JSON")
    SUMMARY_DIR = os.path.join(RESULTS_DIR, "Summary")

    @classmethod
    def ensure_directories(cls):
        """Creates all report and evidence output directories."""
        dirs = [
            cls.RESULTS_DIR, cls.EXCEL_DIR, cls.HTML_DIR,
            cls.SCREENSHOTS_DIR, cls.LOGS_DIR, cls.JSON_DIR, cls.SUMMARY_DIR
        ]
        for d in dirs:
            os.makedirs(d, exist_ok=True)
