import os

class AppiumConfig:
    APPIUM_SERVER_URL = os.environ.get('APPIUM_SERVER_URL', 'http://127.0.0.1:4723/')
    PLATFORM_NAME = 'Android'
    AUTOMATION_NAME = 'UiAutomator2'
    DEVICE_NAME = os.environ.get('DEVICE_NAME', 'Android Emulator')
    APK_PATH = os.path.abspath(os.path.join(
        os.path.dirname(__file__), '..', '..', 'android', 'app', 'build', 'outputs', 'apk', 'debug', 'app-debug.apk'
    ))

    # Mobile Reports Directory
    MOBILE_REPORTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'reports'))
