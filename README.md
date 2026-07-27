# PostureFixPro - AI-Powered Posture Monitoring & Correction Full-Stack System

PostureFixPro is an advanced full-stack solution featuring real-time AI posture analysis, personalized ergonomic feedback, posture alert telemetry, and comprehensive analytics dashboards.

---

## Repository Directory Structure

```
PostureFixPro/
│
├── frontend/             # Flutter Multi-Platform Frontend
│   ├── android/          # Native Android build & Capacitor wrapper
│   ├── ios/              # Native iOS build setup
│   ├── lib/              # Application UI, Controllers, State & Services
│   ├── web/              # Flutter Web entrypoint & icons
│   ├── assets/           # UI media, vectors & illustrations
│   └── pubspec.yaml      # Flutter package manifest
│
├── backend/              # Flask REST API & Analytics Server
│   ├── app.py            # Main Flask app & route initializers
│   ├── config.py         # Database & environment configurations
│   ├── routes/           # REST endpoints (auth, user, session, alerts)
│   ├── models/           # MongoDB schemas & data models
│   ├── services/         # AI analysis & external integrations
│   ├── database/         # MongoDB client initialization
│   ├── templates/        # Backend dashboard templates
│   └── requirements.txt  # Backend Python dependencies
│
├── .github/              # GitHub Actions CI/CD workflows
│   └── workflows/
│       └── deploy-and-test.yml
│
├── automation/           # Selenium E2E Automation Suite
│   ├── config/
│   ├── tests/
│   └── utils/
│
├── docs/                 # Detailed Technical Documentation
│   ├── ARCHITECTURE.md
│   ├── API_DOCUMENTATION.md
│   └── DEVELOPMENT_GUIDE.md
│
├── .env                  # Project environment secrets
├── .gitignore            # Git ignore rules
└── README.md             # Project README
```

---

## Quick Start

### 1. Backend Setup (Flask REST API)
```bash
cd backend
pip install -r requirements.txt
python app.py
```
- API Endpoint: `http://localhost:5000/api`
- Health Check: `http://localhost:5000/health`
- Web Dashboard: `http://localhost:5000`

### 2. Frontend Setup (Flutter App)
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## Technical Documentation
For deeper architecture breakdown, API reference, and testing steps, see:
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)
- [docs/DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md)
