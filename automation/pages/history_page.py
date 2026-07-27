from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class HistoryPage(BasePage):
    HISTORY_SCREEN = (By.ID, "history-screen")
    HISTORY_LIST = (By.ID, "history-list-container")

    def is_loaded(self):
        return self.is_displayed(self.HISTORY_SCREEN)
