from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException
from automation.config.config import Config
from automation.utils.logger import TestLogger

logger = TestLogger.get_logger()

class BasePage:
    def __init__(self, driver):
        self.driver = driver
        self.wait = WebDriverWait(driver, Config.EXPLICIT_WAIT)

    def open(self, path=""):
        target_url = Config.BASE_URL.rstrip('/') + '/' + path.lstrip('/')
        logger.info(f"Navigating to URL: {target_url}")
        self.driver.get(target_url)

    def find_element(self, locator):
        return self.wait.until(EC.presence_of_element_located(locator))

    def find_visible_element(self, locator):
        return self.wait.until(EC.visibility_of_element_located(locator))

    def click(self, locator):
        el = self.find_visible_element(locator)
        el.click()

    def type(self, locator, text):
        el = self.find_visible_element(locator)
        el.clear()
        el.send_keys(text)

    def get_text(self, locator):
        return self.find_visible_element(locator).text.strip()

    def is_displayed(self, locator):
        try:
            return self.find_element(locator).is_displayed()
        except (TimeoutException, NoSuchElementException):
            return False

    def execute_script(self, script, *args):
        return self.driver.execute_script(script, *args)

    def scroll_into_view(self, locator):
        el = self.find_element(locator)
        self.driver.execute_script("arguments[0].scrollIntoView(true);", el)

    def get_current_url(self):
        return self.driver.current_url

    def get_title(self):
        return self.driver.title
