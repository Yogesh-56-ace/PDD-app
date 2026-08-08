# Workspace Rules

## Default Localhost Server & Startup Response Procedure
- When the user asks to "start", "run", or requests the "localhost link":
  1. Immediately launch the server using `python run_all.py` (which runs Flask backend on port 5000 and the MIME-fixed mobile web showcase server on port 3000).
  2. Verify that `http://localhost:3000` is active and returning 200 OK.
  3. Ensure all QA automation Excel reports (Selenium, Appium, and Load testing with 375+ unique test cases each, 0 payment terms) are in place.
  4. Output **`http://localhost:3000`** as the primary link alongside Flask backend (`http://localhost:5000`) and GitHub Actions status link (`https://github.com/Yogesh-56-ace/PDD-app/actions`).
