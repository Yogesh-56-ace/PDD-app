# PostureFixPro - API Documentation

## Base URL
- **Local Development**: `http://localhost:5000/api`
- **Android Emulator**: `http://10.0.2.2:5000/api`

---

## Endpoints Summary

### System & Health
- `GET /health`: Returns system health status and timestamp.
- `GET /`: Serves backend monitoring dashboard.
- `GET /showcase`: Serves mobile app showcase view.

### Authentication
- `POST /api/auth/register`: User registration with email, password, and name.
- `POST /api/auth/login`: User authentication, returns JWT access token.

### User & Profile
- `GET /api/user/status`: Returns current user state (e.g. onboarding completed, active status).
- `POST /api/user/onboarding`: Submits initial user setup parameters (ergonomic baseline, target goal).
- `GET /api/user/profile`: Fetches user profile information.
- `PUT /api/user/profile`: Updates user profile settings and preferences.

### Session Telemetry & AI Posture Tracking
- `POST /api/session/start`: Initializes a posture monitoring session.
- `POST /api/session/end`: Concludes an active session and stores posture scores.
- `GET /api/sessions`: Returns historical session logs.
- `POST /api/ai/analyze-frame`: Analyzes pose landmark coordinates and returns posture score & tilt degree warnings.

### Analytics & Alerts
- `GET /api/stats/weekly`: Returns weekly average score, slumping counts, and screen-time trends.
- `GET /api/alerts`: Fetches recent posture warning alerts.
- `POST /api/alerts`: Records a new posture alert trigger.
