import os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from automation.config.config import AutomationConfig

class DriverFactory:
    @staticmethod
    def get_driver():
        options = ChromeOptions()
        if AutomationConfig.HEADLESS:
            options.add_argument('--headless=new')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        options.add_argument('--disable-gpu')
        options.add_argument('--window-size=1920,1080')
        options.add_argument('--allow-file-access-from-files')
        options.add_argument('--use-fake-ui-for-media-stream') # Allow camera/mic automatically
        options.add_argument('--use-fake-device-for-media-stream')

        driver = webdriver.Chrome(options=options)
        driver.implicitly_wait(AutomationConfig.IMPLICIT_WAIT)
        return driver
