import os
import json
import time
from automation.config.config import Config
from automation.utils.logger import TestLogger

logger = TestLogger.get_logger()

class SummaryGenerator:
    @staticmethod
    def generate_summary(test_results, deployment_status="PASS"):
        Config.ensure_directories()
        
        total = len(test_results)
        passed = sum(1 for t in test_results if t["status"].upper() in ["PASSED", "PASS"])
        failed = sum(1 for t in test_results if t["status"].upper() in ["FAILED", "FAIL"])
        skipped = sum(1 for t in test_results if t["status"].upper() in ["SKIPPED", "SKIP"])
        
        pass_rate = round((passed / max(total, 1)) * 100, 2)
        total_duration = round(sum(float(t.get("duration", 0.1)) for t in test_results), 2)
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime())

        # Module metrics
        modules = {}
        for t in test_results:
            m = t["module"]
            if m not in modules:
                modules[m] = {"total": 0, "pass": 0, "fail": 0}
            modules[m]["total"] += 1
            if t["status"].upper() in ["PASSED", "PASS"]:
                modules[m]["pass"] += 1
            elif t["status"].upper() in ["FAILED", "FAIL"]:
                modules[m]["fail"] += 1

        top_passing = sorted(
            [{"name": m, "rate": round((v["pass"]/v["total"])*100, 1)} for m, v in modules.items()],
            key=lambda x: x["rate"], reverse=True
        )

        failed_items = [t for t in test_results if t["status"].upper() in ["FAILED", "FAIL"]]

        # 1. JSON Export: execution-results.json
        json_path = os.path.join(Config.JSON_DIR, "execution-results.json")
        json_data = {
            "target_url": Config.BASE_URL,
            "timestamp": timestamp,
            "summary": {
                "total": total, "passed": passed, "failed": failed,
                "skipped": skipped, "pass_rate_percentage": pass_rate,
                "duration_seconds": total_duration
            },
            "test_cases": test_results
        }
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(json_data, f, indent=2)

        # 2. Markdown Summary: summary.md
        build_status = "PASS" if pass_rate >= 95 and deployment_status == "PASS" else "FAIL"

        md_content = f"""# Live GitHub Pages E2E Execution Summary

**Deployment URL:**
{Config.BASE_URL}

**Execution Date:**
{timestamp}

**Build Status:**
`{build_status}`

**Deployment Status:**
`{deployment_status}`

**Total Test Cases:**
{total}

**Executed Metrics:**
- **Passed:** {passed}
- **Failed:** {failed}
- **Skipped:** {skipped}

**Pass Percentage:**
`{pass_rate}%`

**Execution Duration:**
{total_duration} seconds

---

### Top Passing Modules
"""
        for m in top_passing[:5]:
            md_content += f"- **{m['name']}:** {m['rate']}%\n"

        md_content += "\n### Failed Tests\n"
        if failed_items:
            for f in failed_items[:10]:
                md_content += f"- **{f['test_id']}** - {f['test_name']} | *Reason:* {f.get('failure_reason', 'N/A')}\n"
        else:
            md_content += "✓ Zero test case failures detected.\n"

        md_content += """
---

### Artifacts Generated
✓ Excel Reports (`Automation_Test_Report.xlsx`, `Failed_Test_Cases.xlsx`, `Passed_Test_Cases.xlsx`, `Summary_Report.xlsx`)
✓ HTML Reports (`execution-report.html`, `dashboard.html`)
✓ Failure Screenshots
✓ System Execution Logs
✓ JSON Results (`execution-results.json`)
"""

        summary_md_path = os.path.join(Config.SUMMARY_DIR, "summary.md")
        with open(summary_md_path, "w", encoding="utf-8") as f:
            f.write(md_content)

        # 3. Publish to GitHub Action Step Summary
        github_summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
        if github_summary_path:
            try:
                with open(github_summary_path, "a", encoding="utf-8") as f:
                    f.write(md_content)
                logger.info(f"Published summary to GITHUB_STEP_SUMMARY: {github_summary_path}")
            except Exception as e:
                logger.error(f"Failed to write to GITHUB_STEP_SUMMARY: {e}")

        logger.info("Summary files generated successfully.")
