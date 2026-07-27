# PostureFixPro - System Architecture

## Full-Stack Architecture Overview

PostureFixPro is organized as a unified full-stack application comprising a **Flutter Frontend**, a **Flask Backend**, an **AI Posture Detection Pipeline**, and a **MongoDB Database**.

```
PostureFixPro/
│
├── frontend/             # Cross-platform Flutter Application
│   ├── android/          # Native Android Configuration & Capacitor Wrapper
│   ├── ios/              # Native iOS Configuration
│   ├── lib/              # Flutter App Source Code (UI, Screens, Controllers, Services)
│   ├── web/              # Web Platform Entry & Static Web Assets
│   ├── assets/           # UI Images, Icons & Media Assets
│   ├── website/          # Landing Page Web Assets
│   └── pubspec.yaml      # Flutter Package Manifest & Dependencies
│
├── backend/              # Flask RESTful API & AI Analytics Engine
│   ├── app.py            # Flask Application Entrypoint & Static Route Handlers
│   ├── config.py         # App Configuration (MongoDB, Secrets, Cloudinary)
│   ├── routes/           # API Blueprint Route Handlers (Auth, User, Session, Alerts, AI)
│   ├── models/           # Data Schemas & Database Entities (MongoDB PyMongo)
│   ├── services/         # Business Logic (AI Analysis, Cloudinary Upload, Auth)
│   ├── database/         # MongoDB Client & Connection Initialization
│   ├── middleware/       # JWT Auth & Request Logging Middleware
│   ├── static/           # Backend Dashboard CSS/JS Static Assets
│   ├── templates/        # Jinja2 HTML Templates (Monitoring Dashboard)
│   └── requirements.txt  # Python Dependencies
│
├── .github/              # CI/CD Workflows (GitHub Actions)
│   └── workflows/
│       └── deploy-and-test.yml
│
├── automation/           # Selenium E2E Automation Testing Suite
│   ├── config/
│   ├── drivers/
│   ├── pages/
│   ├── tests/
│   └── utils/
│
├── docs/                 # System Documentation & Developer Guides
│   ├── ARCHITECTURE.md
│   ├── API_DOCUMENTATION.md
│   └── DEVELOPMENT_GUIDE.md
│
├── .env                  # Environment Variables & API Secrets
├── .gitignore            # Git Exclusion Patterns
└── README.md             # Repository Overview & Quick Start
```

---

## Component Interactions

1. **Frontend (Flutter)**:
   - Built for Android, iOS, and Web.
   - Communicates with Flask backend via RESTful APIs over HTTP/HTTPS.
   - Leverages `google_mlkit_pose_detection` on native mobile and MediaPipe/Web API on Web for real-time posture analysis.

2. **Backend (Python Flask)**:
   - Exposes `/api` endpoints for Authentication (`/api/auth`), User Profile (`/api/user`), Posture Sessions (`/api/session`), Weekly Stats (`/api/stats`), and Alerts (`/api/alerts`).
   - Serves the Web Dashboard at `/` and the Mobile App Showcase at `/showcase`.

3. **Database (MongoDB Atlas)**:
   - Stores User credentials, profile parameters, posture session telemetry, score histories, and alert records.

4. **Cloud Storage (Cloudinary)**:
   - Stores user profile avatars and AI posture snapshot evidence.
