from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class LoginPage(BasePage):
    EMAIL_INPUT = (By.ID, "login-email")
    PASSWORD_INPUT = (By.ID, "login-password")
    LOGIN_BTN = (By.CSS_SELECTOR, "#login-form button[type='submit']")
    GET_STARTED_BTN = (By.XPATH, "//button[contains(., 'Get Started')]")
    REGISTER_TOGGLE = (By.XPATH, "//span[contains(., 'Register here')]")

    def click_get_started(self):
        try:
            self.click(*self.GET_STARTED_BTN)
        except Exception:
            pass

    def login(self, email, password):
        self.type_text(*self.EMAIL_INPUT, email)
        self.type_text(*self.PASSWORD_INPUT, password)
        self.click(*self.LOGIN_BTN)
