# PostureFixPro - Development & Testing Guide

## Environment Setup

### Prerequisites
- Flutter SDK (v3.0.0+)
- Python 3.10+
- MongoDB Instance (Local or MongoDB Atlas)
- Node.js & npm (optional, for Capacitor mobile bundling)

---

## 1. Running the Flask Backend

1. Navigate to the `backend/` directory:
   ```bash
   cd backend
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Ensure `.env` is configured with MongoDB URI and Port:
   ```env
   MONGO_URI=mongodb+srv://<username>:<password>@cluster0.x32kn6o.mongodb.net/posture_ai?retryWrites=true&w=majority
   DB_NAME=posture_ai
   PORT=5000
   DEBUG=True
   SECRET_KEY=posture_fix_pro_super_secret_jwt_key_123!
   ```

4. Start the backend server:
   ```bash
   python app.py
   ```
   The API will launch at `http://localhost:5000`.

---

## 2. Running the Flutter Frontend

1. Navigate to the `frontend/` directory:
   ```bash
   cd frontend
   ```

2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```

3. Launch on Web or connected device:
   ```bash
   # Run Flutter Web
   flutter run -d chrome

   # Build Flutter Web Release Bundle
   flutter build web --release
   ```

---

## 3. Running Automated E2E Tests

From the repository root:
```bash
pip install -r automation/requirements.txt
python automation/tests/test_runner.py
```
Test results and screenshots are saved in `Test Results/`.
