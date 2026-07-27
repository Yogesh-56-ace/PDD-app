from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class ProfilePage(BasePage):
    PROFILE_SCREEN = (By.ID, "profile-screen")
    USER_NAME = (By.ID, "profile-user-name")

    def is_loaded(self):
        return self.is_displayed(self.PROFILE_SCREEN)
