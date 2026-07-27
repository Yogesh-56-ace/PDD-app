from selenium.webdriver.common.by import By
from automation.pages.base_page import BasePage

class UploadPage(BasePage):
    UPLOAD_SCREEN = (By.ID, "upload-image-screen")
    FILE_INPUT = (By.ID, "posture-image-input")
    ANALYZE_SUBMIT_BTN = (By.ID, "web-start-analysis-btn")
    UPLOAD_DROPZONE = (By.CLASS_NAME, "upload-dropzone")
    PREVIEW_IMAGE = (By.ID, "uploaded-image-preview")

    def is_loaded(self):
        return self.is_displayed(self.UPLOAD_SCREEN) or self.is_displayed(self.UPLOAD_DROPZONE)

    def upload_file(self, file_path):
        el = self.find_element(self.FILE_INPUT)
        el.send_keys(file_path)

    def trigger_analysis(self):
        self.execute_script("if (typeof startProcessingFlow === 'function') startProcessingFlow();")
