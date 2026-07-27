from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class HomePage(BasePage):
    # Locators matching index.html
    TITLE = (By.TAG_NAME, "title")
    SPLASH_SCREEN = (By.ID, "splash-screen")
    HOME_SCREEN = (By.ID, "home-screen")
    APP_HEADER = (By.CLASS_NAME, "app-header")
    HERO_CARD = (By.CLASS_NAME, "hero-card")
    ANALYZE_IMAGE_BTN = (By.XPATH, "//button[contains(., 'Analyze Posture') or contains(., 'Analyze') or contains(., 'Get Started')]")

    def is_loaded(self):
        return (
            self.is_displayed(self.SPLASH_SCREEN) or
            self.is_displayed(self.HOME_SCREEN) or
            self.is_displayed(self.APP_HEADER) or
            len(self.get_title()) > 0
        )

    def click_analyze_image(self):
        self.click(self.ANALYZE_IMAGE_BTN)

    def navigate_to_screen(self, screen_id):
        self.execute_script(f"if (typeof navigateTo === 'function') navigateTo('{screen_id}');")
