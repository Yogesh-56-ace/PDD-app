from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class MonitoringPage(BasePage):
    MONITORING_SCREEN = (By.ID, "monitoring-screen")
    CAMERA_PREVIEW = (By.ID, "camera-feed")
    ALERT_TOGGLE = (By.ID, "alert-audio-toggle")

    def is_loaded(self):
        return self.is_displayed(self.MONITORING_SCREEN)
