import os
import json
from automation.config.config import Config
from automation.utils.logger import TestLogger

logger = TestLogger.get_logger()

class HTMLReportGenerator:
    @staticmethod
    def generate_html_reports(test_results):
        """Generates execution-report.html and dashboard.html."""
        Config.ensure_directories()

        total_tests = len(test_results)
        passed_tests = sum(1 for t in test_results if t["status"].upper() in ["PASSED", "PASS"])
        failed_tests = sum(1 for t in test_results if t["status"].upper() in ["FAILED", "FAIL"])
        skipped_tests = sum(1 for t in test_results if t["status"].upper() in ["SKIPPED", "SKIP"])
        
        pass_rate = round((passed_tests / max(total_tests, 1)) * 100, 2)
        total_duration = round(sum(float(t.get("duration", 0.1)) for t in test_results), 2)

        # Module breakdown
        modules = {}
        for t in test_results:
            m = t["module"]
            if m not in modules:
                modules[m] = {"total": 0, "pass": 0, "fail": 0, "skip": 0}
            modules[m]["total"] += 1
            st = t["status"].upper()
            if st in ["PASSED", "PASS"]:
                modules[m]["pass"] += 1
            elif st in ["FAILED", "FAIL"]:
                modules[m]["fail"] += 1
            else:
                modules[m]["skip"] += 1

        # Render HTML template
        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PostureFixPro - Live E2E Selenium Execution Report</title>
    <style>
        :root {{
            --bg: #0F172A;
            --card-bg: #1E293B;
            --text-main: #F8FAFC;
            --text-muted: #94A3B8;
            --primary: #10B981;
            --danger: #EF4444;
            --warning: #F59E0B;
            --border: #334155;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg);
            color: var(--text-main);
            margin: 0;
            padding: 24px;
        }}
        .header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-bottom: 20px;
            border-bottom: 1px solid var(--border);
            margin-bottom: 24px;
        }}
        .header h1 {{ margin: 0; font-size: 24px; color: var(--primary); }}
        .header .url {{ font-size: 13px; color: var(--text-muted); font-family: monospace; }}
        
        .metrics-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 16px;
            margin-bottom: 28px;
        }}
        .metric-card {{
            background: var(--card-bg);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 16px;
            text-align: center;
        }}
        .metric-card .val {{ font-size: 28px; font-weight: 800; margin-top: 4px; }}
        .metric-card.pass .val {{ color: var(--primary); }}
        .metric-card.fail .val {{ color: var(--danger); }}
        .metric-card.skip .val {{ color: var(--warning); }}

        table {{
            width: 100%;
            border-collapse: collapse;
            background: var(--card-bg);
            border-radius: 12px;
            overflow: hidden;
            border: 1px solid var(--border);
        }}
        th, td {{
            padding: 12px 16px;
            text-align: left;
            border-bottom: 1px solid var(--border);
            font-size: 13px;
        }}
        th {{ background: #090D16; color: var(--text-muted); text-transform: uppercase; font-size: 11px; }}
        .badge {{
            display: inline-block;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 700;
        }}
        .badge.pass {{ background: rgba(16, 185, 129, 0.15); color: var(--primary); }}
        .badge.fail {{ background: rgba(239, 68, 68, 0.15); color: var(--danger); }}
        .badge.skip {{ background: rgba(245, 158, 11, 0.15); color: var(--warning); }}
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>PostureFixPro E2E Execution Dashboard</h1>
            <div class="url">Target BASE_URL: {Config.BASE_URL}</div>
        </div>
        <div style="text-align: right;">
            <div style="font-size: 14px; font-weight: 700;">Status: {'PASSED' if pass_rate >= 95 else 'FAILED'}</div>
            <div style="font-size: 12px; color: var(--text-muted);">Duration: {total_duration}s</div>
        </div>
    </div>

    <div class="metrics-grid">
        <div class="metric-card">
            <div style="font-size: 12px; color: var(--text-muted);">Total Executed</div>
            <div class="val">{total_tests}</div>
        </div>
        <div class="metric-card pass">
            <div style="font-size: 12px; color: var(--text-muted);">Passed</div>
            <div class="val">{passed_tests}</div>
        </div>
        <div class="metric-card fail">
            <div style="font-size: 12px; color: var(--text-muted);">Failed</div>
            <div class="val">{failed_tests}</div>
        </div>
        <div class="metric-card skip">
            <div style="font-size: 12px; color: var(--text-muted);">Skipped</div>
            <div class="val">{skipped_tests}</div>
        </div>
        <div class="metric-card pass">
            <div style="font-size: 12px; color: var(--text-muted);">Pass Percentage</div>
            <div class="val">{pass_rate}%</div>
        </div>
    </div>

    <h2 style="font-size: 18px; margin-bottom: 14px;">Executed Test Specifications ({total_tests})</h2>
    <table>
        <thead>
            <tr>
                <th>Test ID</th>
                <th>Module</th>
                <th>Test Specification Name</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Duration (s)</th>
                <th>Failure Diagnostics</th>
            </tr>
        </thead>
        <tbody>
"""

        for t in test_results:
            st = t["status"].upper()
            badge_cls = "pass" if st in ["PASSED", "PASS"] else ("fail" if st in ["FAILED", "FAIL"] else "skip")
            html_content += f"""
            <tr>
                <td><strong>{t['test_id']}</strong></td>
                <td>{t['module']}</td>
                <td>{t['test_name']}</td>
                <td>{t.get('priority', 'P2')}</td>
                <td><span class="badge {badge_cls}">{st}</span></td>
                <td>{round(float(t.get('duration', 0.1)), 3)}s</td>
                <td style="color: var(--danger); font-family: monospace; font-size: 11px;">{t.get('failure_reason', '')}</td>
            </tr>"""

        html_content += """
        </tbody>
    </table>
</body>
</html>"""

        report_path = os.path.join(Config.HTML_DIR, "execution-report.html")
        dashboard_path = os.path.join(Config.HTML_DIR, "dashboard.html")

        with open(report_path, "w", encoding="utf-8") as f:
            f.write(html_content)
        with open(dashboard_path, "w", encoding="utf-8") as f:
            f.write(html_content)

        logger.info(f"Generated HTML report at: {report_path}")
