from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class AuthPage(BasePage):
    LOGIN_SCREEN = (By.ID, "login-screen")
    REGISTER_SCREEN = (By.ID, "register-screen")
    EMAIL_INPUT = (By.ID, "login-email-input")
    PASSWORD_INPUT = (By.ID, "login-password-input")
    LOGIN_SUBMIT_BTN = (By.ID, "login-submit-btn")

    def is_loaded(self):
        return self.is_displayed(self.LOGIN_SCREEN) or self.is_displayed(self.REGISTER_SCREEN)
