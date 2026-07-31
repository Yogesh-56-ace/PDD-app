from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class DashboardPage(BasePage):
    STATUS_BADGE = (By.ID, "home-badge")
    STATUS_TITLE = (By.ID, "home-status-title")
    START_MONITORING_BTN = (By.XPATH, "//button[contains(., 'Start Monitoring')]")
    PROFILE_AVATAR = (By.ID, "home-user-avatar")

    def get_status_title(self):
        return self.get_text(*self.STATUS_TITLE)

    def click_start_monitoring(self):
        self.click(*self.START_MONITORING_BTN)
