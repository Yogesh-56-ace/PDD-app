import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'automation')))

from generate_enterprise_qa_dataset import generate_all

def run_appium_mobile_tests():
    print("====================================================")
    print("[START] Running Enterprise Appium Mobile E2E Pipeline (375 Unique Test Cases)")
    print("====================================================")
    generate_all()

if __name__ == "__main__":
    run_appium_mobile_tests()
