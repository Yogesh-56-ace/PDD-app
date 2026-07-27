from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class StatsPage(BasePage):
    STATS_SCREEN = (By.ID, "stats-screen")
    WEEKLY_CHART = (By.ID, "weekly-stats-chart")

    def is_loaded(self):
        return self.is_displayed(self.STATS_SCREEN)
