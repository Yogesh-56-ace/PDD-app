# PostureFixPro Automation Framework Guide

Enterprise-grade Selenium E2E Automation Framework testing against the **LIVE GitHub Pages Deployment**:
`https://yogesh-56-ace.github.io/posturefixpro-app/`

---

## Folder Structure

```text
automation/
├── config/
│   └── config.py               # BASE_URL, timeouts, paths
├── data/
│   └── test_data.py            # Input matrices, viewports, invalid payloads
├── drivers/
│   └── driver_factory.py       # Headless Chrome driver initialization
├── pages/
│   ├── base_page.py            # Core POM explicit waits & element wrappers
│   ├── home_page.py            # Home screen POM
│   ├── upload_page.py          # Upload screen POM
│   ├── results_page.py         # AI Posture Report screen POM
│   ├── monitoring_page.py      # Camera monitoring POM
│   ├── history_page.py         # Assessment logs POM
│   ├── stats_page.py           # Analytics charts POM
│   ├── profile_page.py         # Profile & Settings POM
│   └── auth_page.py            # Login & Register modal POM
├── utils/
│   ├── logger.py               # Execution file & console logging
│   ├── screenshot_utils.py     # Failure screenshot capturer
│   ├── excel_report_generator.py # Openpyxl 6-sheet Excel report generator
│   ├── html_report_generator.py  # Interactive HTML dashboard generator
│   └── summary_generator.py    # JSON export & GitHub Actions step summary builder
└── tests/
    └── test_runner.py          # 440 Executable E2E Test Suite Runner
```

---

## 1. Local Execution Guide

### Prerequisites
- Python 3.10+
- Google Chrome Browser

### Step-by-Step Instructions
1. Install Python dependencies:
   ```bash
   pip install -r automation/requirements.txt
   ```
2. Execute the live test suite:
   ```bash
   python automation/tests/test_runner.py
   ```
3. To override the target URL locally (e.g. against staging):
   ```bash
   set BASE_URL=https://yogesh-56-ace.github.io/posturefixpro-app/
   python automation/tests/test_runner.py
   ```
4. View generated evidence reports in `Test Results/`:
   - `Excel/Automation_Test_Report.xlsx`
   - `HTML/execution-report.html`

---

## 2. GitHub Repository Configuration Guide

To enable automated deployment and testing on every code push:

1. Open your GitHub Repository: `https://github.com/Yogesh-56-ace/posturefixpro-app`
2. Go to **Settings** -> **Pages**:
   - **Source:** Select **Deploy from a branch** or **GitHub Actions**.
   - **Branch:** Select `gh-pages` / `/ (root)` if deploying from branch.
3. Go to **Settings** -> **Actions** -> **General**:
   - Under **Workflow permissions**, select **Read and write permissions**.
   - Check **Allow GitHub Actions to create and approve pull requests**.
4. Push code to the `main` branch to trigger `.github/workflows/deploy-and-test.yml`.

---

## 3. CI/CD Execution Guide

The GitHub Actions workflow runs automatically on every `push`, `pull_request`, or `workflow_dispatch`.

Pipeline Stages:
1. **Checkout & Dependencies:** Sets up Python 3.10 and installs `selenium`, `openpyxl`, `jinja2`.
2. **Build & Static Analysis:** Validates `index.html` and `app.js` syntax.
3. **Deploy to GitHub Pages:** Publishes static web assets to `gh-pages`.
4. **Verification:** Sends HTTP HEAD/GET request to `https://yogesh-56-ace.github.io/posturefixpro-app/`.
5. **Selenium E2E Suite:** Runs 440 headless test cases against the live deployment.
6. **Artifact Upload:** Uploads all Excel, HTML, Screenshot, and Log evidence artifacts (30-day retention).
7. **Job Summary:** Publishes full execution breakdown to GitHub Actions UI.

---

## 4. Troubleshooting Guide

- **Failure: `HTTP 404` or Deployment Propagation Delay**
  - *Cause:* GitHub Pages DNS takes a few seconds on first deployment.
  - *Fix:* The workflow includes a 15-second grace wait and retry mechanism automatically.
- **Failure: Chrome Driver Mismatch**
  - *Cause:* Local Chrome browser auto-updated.
  - *Fix:* `webdriver-manager` automatically fetches the matching ChromeDriver binary.
- **Failure: Pass Rate Threshold Drop (<95%)**
  - *Cause:* Test failures exceeded 5%.
  - *Fix:* Inspect `Test Results/Screenshots/` and `Test Results/Logs/execution.log` attached in the GitHub Action run artifact.
