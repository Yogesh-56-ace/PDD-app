import os
import time
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from automation.config.config import AutomationConfig

class BasePage:
    def __init__(self, driver):
        self.driver = driver
        self.wait = WebDriverWait(driver, AutomationConfig.EXPLICIT_WAIT)

    def navigate_to(self, url=None):
        target_url = url or AutomationConfig.BASE_URL
        self.driver.get(target_url)

    def find_element(self, by, value):
        return self.wait.until(EC.presence_of_element_located((by, value)))

    def click(self, by, value):
        element = self.wait.until(EC.element_to_be_clickable((by, value)))
        element.click()

    def type_text(self, by, value, text):
        element = self.find_element(by, value)
        element.clear()
        element.send_keys(text)

    def get_text(self, by, value):
        return self.find_element(by, value).text

    def capture_screenshot(self, filename):
        os.makedirs(AutomationConfig.SCREENSHOTS_DIR, exist_ok=True)
        path = os.path.join(AutomationConfig.SCREENSHOTS_DIR, filename)
        self.driver.save_screenshot(path)
        return path
