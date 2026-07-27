import os
import time
from automation.config.config import Config
from automation.utils.logger import TestLogger

logger = TestLogger.get_logger()

class ScreenshotUtils:
    @staticmethod
    def capture_screenshot(driver, test_id):
        """Captures screenshot on test failure and saves to Screenshots directory."""
        try:
            Config.ensure_directories()
            timestamp = time.strftime("%Y%m%d_%H%M%S")
            filename = f"{test_id}_{timestamp}.png"
            filepath = os.path.join(Config.SCREENSHOTS_DIR, filename)

            driver.save_screenshot(filepath)
            logger.info(f"Screenshot captured for failure [{test_id}]: {filepath}")
            return filepath
        except Exception as e:
            logger.error(f"Failed to capture screenshot for [{test_id}]: {e}")
            return None
