from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class ResultsPage(BasePage):
    RESULTS_SCREEN = (By.ID, "results-screen")
    SCORE_BADGE = (By.ID, "results-score")
    VERDICT_TEXT = (By.ID, "results-verdict")
    STANDING_SVG_GROUP = (By.ID, "svg-pose-standing")
    SITTING_SVG_GROUP = (By.ID, "svg-pose-sitting")
    PROBLEMS_CONTAINER = (By.ID, "web-problems-list")
    EXERCISES_CONTAINER = (By.ID, "web-exercises-list")
    BACK_HOME_BTN = (By.XPATH, "//button[contains(@onclick, 'home-screen')]")

    def is_loaded(self):
        return self.is_displayed(self.RESULTS_SCREEN)

    def get_score_text(self):
        return self.get_text(self.SCORE_BADGE)

    def is_sitting_pose_visible(self):
        el = self.find_element(self.SITTING_SVG_GROUP)
        return el.is_displayed() and el.value_of_css_property("display") != "none"

    def is_standing_pose_visible(self):
        el = self.find_element(self.STANDING_SVG_GROUP)
        return el.is_displayed() and el.value_of_css_property("display") != "none"
