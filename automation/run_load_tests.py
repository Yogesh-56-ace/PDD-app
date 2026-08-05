import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from generate_enterprise_qa_dataset import generate_all

def run_load_and_performance_tests():
    print("====================================================")
    print("[START] Running Enterprise Performance & Load Pipeline (375 Unique Test Cases)")
    print("====================================================")
    generate_all()

if __name__ == "__main__":
    run_load_and_performance_tests()
