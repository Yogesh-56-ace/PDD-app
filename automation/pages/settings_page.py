from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class SettingsPage(BasePage):
    SETTINGS_SCREEN = (By.ID, "settings-screen")

    def is_loaded(self):
        return self.is_displayed(self.SETTINGS_SCREEN)
