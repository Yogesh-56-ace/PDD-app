import subprocess
import sys
import time
import os

print("=" * 60)
print("[INFO] Starting PostureFixPro Backend & Frontend Servers...")
print("=" * 60)

root_dir = os.path.dirname(os.path.abspath(__file__))

# 1. Launch Flask Backend (Port 5000)
backend_cmd = [sys.executable, os.path.join(root_dir, "backend", "app.py")]
print("[1/2] Starting Flask Backend on http://localhost:5000 ...")
backend_proc = subprocess.Popen(backend_cmd, cwd=root_dir)

time.sleep(2)

# 2. Launch Mobile Web Showcase Frontend (Port 3000) using Custom MIME Fix Server
frontend_cmd = [sys.executable, os.path.join(root_dir, "serve_frontend.py")]
print("[2/2] Starting Mobile Web Showcase Frontend on http://localhost:3000 ...")
frontend_proc = subprocess.Popen(frontend_cmd, cwd=root_dir)

print("\n" + "=" * 60)
print("[SUCCESS] BOTH SERVERS ARE ACTIVE & STYLED!")
print("Frontend Mobile Web App: http://localhost:3000")
print("Backend API Server:      http://localhost:5000")
print("Backend Health Check:   http://localhost:5000/health")
print("Alternative Flask Link: http://localhost:5000/app")
print("=" * 60)
print("Press Ctrl+C to stop both servers.\n")

try:
    backend_proc.wait()
    frontend_proc.wait()
except KeyboardInterrupt:
    print("\nStopping servers...")
    backend_proc.terminate()
    frontend_proc.terminate()
    print("Servers shut down successfully.")
