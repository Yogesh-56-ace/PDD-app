import os
import sys
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from automation.config.config import Config

class DriverFactory:
    @staticmethod
    def create_driver():
        """Initializes Chrome WebDriver with Headless capabilities and CI performance flags."""
        options = Options()

        if Config.HEADLESS:
            options.add_argument("--headless=new")

        # Essential flags for CI / Docker / GitHub Actions
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")
        options.add_argument("--window-size=1920,1080")
        options.add_argument("--disable-notifications")
        options.add_argument("--disable-extensions")
        options.add_argument("--disable-popup-blocking")
        options.add_argument("--ignore-certificate-errors")
        options.add_argument("--allow-running-insecure-content")
        options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36")

        try:
            # Use ChromeDriverManager for seamless automatic driver management
            service = Service(ChromeDriverManager().install())
            driver = webdriver.Chrome(service=service, options=options)
        except Exception as e:
            # Fallback for CI runners with pre-installed chromedriver
            driver = webdriver.Chrome(options=options)

        driver.implicitly_wait(Config.IMPLICIT_WAIT)
        driver.set_page_load_timeout(Config.PAGE_LOAD_TIMEOUT)
        return driver
