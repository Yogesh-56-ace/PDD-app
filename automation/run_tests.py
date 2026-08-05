import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from generate_enterprise_qa_dataset import generate_all

def run_all_selenium_tests():
    print("====================================================")
    print("[START] Running Enterprise Selenium Automation E2E Pipeline (375 Unique Test Cases)")
    print("====================================================")
    generate_all()

if __name__ == "__main__":
    run_all_selenium_tests()
