import os
import random
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

# Ensure reproducible realistic random seed
random.seed(42)

modules = [
    "Login", "Registration", "Authentication", "Dashboard", "Search",
    "User Profile", "Cart", "Wishlist", "Checkout", "Payment",
    "Orders", "Notifications", "Settings", "Reports", "API",
    "Performance", "Security", "Mobile", "Admin Panel"
]

priorities = ["Low", "Medium", "High", "Critical"]
priority_weights = [0.20, 0.45, 0.25, 0.10]

statuses = ["Passed", "Failed", "Skipped", "Blocked"]
status_weights = [0.84, 0.08, 0.05, 0.03]

test_templates = {
    "Login": [
        "Verify valid credentials login with remember me option enabled",
        "Validate error message when submitting invalid password on login form",
        "Test SQL injection payload rejection on username login input field",
        "Verify multi-factor authentication (MFA) TOTP code challenge prompt",
        "Test account lockout policy after 5 consecutive failed login attempts",
        "Validate password visibility toggle icon state transition",
        "Verify session cookie HttpOnly and Secure flags post-login",
        "Test social SSO login via Google OAuth 2.0 provider integration",
        "Validate Apple ID sign-in authorization code exchange flow",
        "Verify automatic redirect to requested URL after successful login",
        "Test rate-limiting protection against brute force attacks on /api/auth/login",
        "Validate session expiration handling after 15 minutes of idle inactivity",
        "Verify active user session termination upon password reset",
        "Test SAML 2.0 enterprise SSO assertion response processing",
        "Validate persistent remember me token refresh mechanism",
        "Verify login error handling during database connection timeout",
        "Test account recovery password reset link generation and email delivery",
        "Validate biometric Face ID authentication fallback on iOS app login",
        "Verify magic link passwordless authentication email dispatch",
        "Validate captcha challenge display on suspicious IP address login attempt"
    ],
    "Registration": [
        "Verify new user account registration with valid mandatory fields",
        "Validate real-time password strength meter UI indicator feedback",
        "Test email address uniqueness validation during user registration",
        "Verify account verification link token generation and email dispatch",
        "Validate mobile phone number E.164 format validation with country code",
        "Test terms of service and privacy policy mandatory checkbox validation",
        "Verify registration form submission with missing required fields",
        "Validate reCAPTCHA v3 challenge verification on high-risk registration attempts",
        "Test rejection of disposable temporary email domain registrations",
        "Verify automated onboarding welcome email trigger upon registration",
        "Test XSS payload sanitization in full name registration input field",
        "Validate password confirmation mismatch inline error state styling",
        "Verify company registration workflow with tax identification number",
        "Validate referral code discount token application during signup",
        "Test registration throttling to prevent automated bot account creation",
        "Verify profile initial avatar creation based on user initials",
        "Validate age verification checkbox enforcement for age-restricted accounts",
        "Test user profile data pre-population via Google OAuth signup",
        "Verify user agreement audit log entry creation upon registration",
        "Validate error handling when email delivery service fails during registration"
    ],
    "Authentication": [
        "Verify JWT bearer access token issuance on successful authentication",
        "Validate refresh token rotation mechanism upon access token expiration",
        "Test API request rejection when bearer token signature is tampered",
        "Verify public key signature verification for RS256 algorithm JWTs",
        "Test CSRF token validation on state-modifying POST requests",
        "Validate bearer token instant revocation upon user logout action",
        "Verify biometrics authentication fallback to secondary PIN code",
        "Test invalid auth header format returns HTTP 401 Unauthorized response",
        "Validate OAuth 2.0 scope authorization enforcement for granular endpoints",
        "Verify session token encryption standard compliance (AES-256-GCM)",
        "Test API gateway token introspection response latency",
        "Validate single active session policy enforcement per user account",
        "Verify cross-origin token sharing restrictions via strict CORS policy",
        "Test JWT payload claim validation for issuer and audience targets",
        "Validate password hash upgrade algorithm (Argon2id / bcrypt cost 12)",
        "Verify secure token storage in Android EncryptedSharedPreferences",
        "Test iOS Keychain item access permissions for authentication tokens",
        "Validate session token renewal on user privilege escalation",
        "Verify automatic logout on concurrent login from different geographic IP",
        "Test open redirect vulnerability prevention in post-auth return parameter"
    ],
    "Dashboard": [
        "Verify real-time KPI summary metrics cards render accurately on load",
        "Validate date range picker filter updates analytical charts dynamically",
        "Test interactive line chart tooltip hover performance under 60fps",
        "Verify grid dashboard widget drag-and-drop position customization",
        "Validate metric percentage delta calculations against backend stats API",
        "Test dark mode color theme toggle state persistence across browser reloads",
        "Verify quick action shortcuts trigger corresponding modal dialogs",
        "Validate live WebSocket telemetry data feed updates without UI stuttering",
        "Test dashboard data fallback UI when analytics backend service is offline",
        "Verify export dashboard metrics summary report to PDF document",
        "Validate user activity feed live polling update interval",
        "Test custom dashboard layout reset to system default configuration",
        "Verify system health indicator banner color coding for active incidents",
        "Validate chart zoom and pan control responsiveness on touch screens",
        "Test metric threshold alert toast notifications display correctly",
        "Verify lazy loading of off-screen dashboard widget components",
        "Validate dashboard filter state reflection in browser URL query params",
        "Test RBAC widget visibility control based on logged-in user role",
        "Verify responsive column stacking on tablet and mobile viewport sizes",
        "Validate screen reader ARIA labels for accessibility compliance on charts"
    ],
    "Search": [
        "Verify search input auto-complete suggestions response time under 150ms",
        "Validate fuzzy string matching algorithm for misspelled search queries",
        "Test multi-facet filtering combination (Category + Price Range + Rating)",
        "Verify search results pagination navigation and items per page selector",
        "Validate zero search results empty state UI and recommended items",
        "Test search query sanitization against SQL and NoSQL injection payloads",
        "Verify search history recent items persistence in browser local storage",
        "Validate search index input debounce timing during continuous fast typing",
        "Test search result sorting by price low-to-high and relevance algorithms",
        "Verify highlighted matching text snippet rendering in search results",
        "Validate search bar clear button resets filter state and query string",
        "Test Elasticsearch cluster query timeout resilience under heavy load",
        "Verify voice search audio input recognition and text query translation",
        "Validate product barcode scanner search functionality on mobile app",
        "Test search filter pill tags removal updates search results instantly",
        "Verify search landing page canonical URL generation for SEO",
        "Validate search query analytics tracking event payload structure",
        "Test search results layout toggle between grid view and list view",
        "Verify exact match SKU search routes directly to product details page",
        "Validate multi-language search support for UTF-8 special characters"
    ],
    "User Profile": [
        "Verify profile avatar image file upload and thumbnail image crop",
        "Validate personal details update triggers success toast notification",
        "Test change password workflow with current password verification step",
        "Verify email address change notification sent to old and new addresses",
        "Validate phone number SMS OTP code verification flow",
        "Test address book entry creation, edit, and soft deletion operations",
        "Verify profile completeness progress indicator percentage calculation",
        "Validate user communication preferences toggle switch state saving",
        "Test account privacy setting toggles for public profile visibility",
        "Verify user profile data download request compliant with GDPR standards",
        "Validate maximum image upload file size restriction (5MB limit)",
        "Test image format validation accepting only JPG, PNG, and WebP files",
        "Verify user bio text field character limit counter enforcement",
        "Validate social media profile link URL format validation regex",
        "Test account timezone selection updates timestamp displays application-wide",
        "Verify primary shipping address badge indicator in address manager",
        "Validate soft deleted user account recovery within 30-day grace period",
        "Test profile update audit log event creation in admin backend",
        "Verify user profile page rendering performance under 200ms DOM load",
        "Validate profile page accessibility keyboard navigation focus ring"
    ],
    "Cart": [
        "Verify add single product item to cart updates header cart badge count",
        "Validate product item quantity increment and decrement stepper controls",
        "Test product item removal from cart recalculates subtotal pricing",
        "Verify out-of-stock product handling in cart with warning banner",
        "Validate promo coupon code validation and discount calculation logic",
        "Test cart session synchronization between mobile app and web browser",
        "Verify cart subtotal, estimated tax, and shipping fee calculation breakdown",
        "Validate guest cart items migration upon user account login",
        "Test bulk clear all cart items confirmation dialog action",
        "Verify maximum quantity purchase limit error message display",
        "Validate item price change alert banner when cart item price updates",
        "Test save for later list transfer from active shopping cart",
        "Verify gift wrapping option checkbox adds itemized gift fee",
        "Validate cart persistence across browser tab closure and re-opening",
        "Test inventory reservation lock duration on cart items (15 min timer)",
        "Verify cross-sell product recommendation carousel in cart page",
        "Validate free shipping progress bar threshold calculation indicator",
        "Test bundle product discount application when all bundle items in cart",
        "Verify mini-cart dropdown drawer rendering on header hover action",
        "Validate cart item thumbnail image fallback when image URL fails to load"
    ],
    "Wishlist": [
        "Verify move item from wishlist to active shopping cart",
        "Validate wishlist item price drop email notification trigger preference",
        "Test creation of custom named wishlist folders and collections",
        "Verify wishlist sharing via unique public web link generation",
        "Validate duplicate product item prevention within same wishlist folder",
        "Test remove product item from wishlist with undo toast action",
        "Verify private vs public wishlist privacy toggle settings",
        "Validate total wishlist count badge on user account navigation bar",
        "Test wishlist items sorting by date added and price low-to-high",
        "Verify out-of-stock badge overlay on wishlist product cards",
        "Validate quick add all wishlist items to shopping cart action",
        "Test wishlist items batch deletion via bulk selection checkboxes",
        "Verify wishlist migration from guest local storage to logged-in user profile",
        "Validate stock back-in-stock notification subscription from wishlist",
        "Test wishlist search and filtering by product category tags",
        "Verify social media share buttons for wishlist collection page",
        "Validate wishlist item notes and priority ranking custom inputs",
        "Test wishlist load performance with over 100 saved product items",
        "Verify drag-and-drop product re-ordering within custom wishlist folder",
        "Validate wishlist analytics tracking event for item favorited action"
    ],
    "Checkout": [
        "Verify multi-step checkout progress bar step indicator navigation",
        "Validate billing address copy from shipping address checkbox toggle",
        "Test express checkout via Apple Pay and Google Pay one-click payment",
        "Verify order summary line items and total pricing breakdown pre-submission",
        "Validate shipping address Zip code auto-lookup and state autofill",
        "Test delivery method selection (Standard, Express, Overnight) price updates",
        "Verify order placement confirmation screen rendering with order ID",
        "Validate checkout session timeout handling after 20 minutes idle",
        "Test shipping restrictions enforcement for hazardous or oversized items",
        "Verify address validation API correction suggestion modal display",
        "Validate guest checkout option flow without mandatory account creation",
        "Test discount code application during checkout step 3",
        "Verify checkout form field state preservation on browser back button",
        "Validate error handling when selected shipping carrier service fails",
        "Test custom delivery instructions text field character limit",
        "Verify age-restricted product verification step during checkout",
        "Validate split shipping address option for multi-item orders",
        "Test currency conversion display on international shipping checkout",
        "Verify checkout page SSL encryption security badge indicators",
        "Validate abandonment recovery trigger email dispatch after 1 hour"
    ],
    "Payment": [
        "Verify Credit Card payment processing via Stripe SDK integration",
        "Validate 3D Secure 2.0 OTP authentication challenge modal window",
        "Test invalid credit card number Luhn algorithm validation check",
        "Verify PayPal Sandbox gateway redirect and IPN webhook callback handling",
        "Validate saved credit card tokenization compliance with PCI-DSS",
        "Test handling of declined card payment error messages and retry prompt",
        "Verify installment payment plan (Klarna / Afterpay) checkout selection",
        "Validate CVV security code input masking and validation rules",
        "Test expired credit card expiration date selection inline error",
        "Verify refund webhook processing updates payment status in database",
        "Validate multi-currency payment conversion rate calculation accuracy",
        "Test payment gateway fallback mechanism when primary gateway times out",
        "Verify stored credit card deletion from user payment wallet",
        "Validate store credit and gift card balance partial payment deduction",
        "Test duplicate charge prevention idempotency key verification",
        "Verify payment receipt email dispatch with transaction reference ID",
        "Validate crypto currency payment wallet connection and transaction signature",
        "Test direct bank transfer (ACH / SEPA) pending status workflow",
        "Verify payment method selection persistence for recurring subscriptions",
        "Validate fraud risk scoring check blocks high-risk payment transactions"
    ],
    "Orders": [
        "Verify order history list displays recent orders with correct status badges",
        "Validate order status timeline tracker (Placed, Processing, Shipped, Delivered)",
        "Test order cancellation request within allowed cancellation timeframe window",
        "Verify PDF invoice document download generation from order details page",
        "Validate return and refund workflow initiation for eligible items",
        "Test order shipment tracking package link opens carrier tracking site",
        "Verify re-order action adds previous order line items to shopping cart",
        "Validate shipment delivery notification email and push alert trigger",
        "Test partial shipment order status UI rendering when items ship separately",
        "Verify order details page printing stylesheet layout optimization",
        "Validate order search filtering by Order ID, date range, and status",
        "Test customer support ticket creation directly linked to order ID",
        "Verify order item review and rating submission action workflow",
        "Validate export user order history data to CSV format download",
        "Test order modification address change request before shipment dispatch",
        "Verify gift order message card rendering in order packing slip preview",
        "Validate digital product download link activation post-order payment",
        "Test order escalation for missing or damaged package delivery claims",
        "Verify order confirmation SMS notification dispatch to customer phone",
        "Validate historical order archiving for orders older than 24 months"
    ],
    "Notifications": [
        "Verify push notification payload processing when app is in background state",
        "Validate in-app notification center unread badge counter badge updates",
        "Test notification channels preference toggles (Email, SMS, Push Alerts)",
        "Verify deep link URL navigation when tapping push notification alert",
        "Validate marking all unread notifications as read in bulk action",
        "Test promotional marketing email unsubscribing link processing",
        "Verify order shipment real-time push notification delivery latency",
        "Validate system security alert notification trigger on new device login",
        "Test quiet hours schedule suppresses non-critical push notifications",
        "Verify rich push notifications with image thumbnail and action buttons",
        "Validate Web Push notification permission request prompt in browser",
        "Test APNS / FCM device token registration and renewal workflow",
        "Verify notification message localization matching device language",
        "Validate expired notification auto-cleanup background cron job",
        "Test broadcast admin notification delivery to target user segment",
        "Verify notification click-through rate analytics tracking event",
        "Validate sound and vibration haptic feedback settings for push alerts",
        "Test notification payload size limit handling (FCM 4KB limit check)",
        "Verify inbox notification search and category filtering (System, Promo)",
        "Validate fallback to SMS when push notification delivery fails"
    ],
    "Settings": [
        "Verify language localization switching between English, Spanish, and French",
        "Validate currency selector updates product pricing display across app",
        "Test account data export download compliant with GDPR data portability",
        "Verify permanent account deletion confirmation modal and password re-entry",
        "Validate application theme selection (Light, Dark, System Default)",
        "Test auto-update software preferences toggle switch state persistence",
        "Verify storage cache clearing action frees allocated local storage",
        "Validate network data usage saver mode limits high-res image loads",
        "Test default shipping address selection in account settings module",
        "Verify third-party app permissions revoking in security settings",
        "Validate accessibility font size scaling adjustment preview",
        "Test biometrics login requirement toggle in application settings",
        "Verify connected social accounts unlinking workflow",
        "Validate developer mode API key generation and secret copy action",
        "Test default payment method selection in billing preferences",
        "Verify cookie consent banner preferences update action",
        "Validate session timeout duration custom selector (15m, 30m, 1h, 4h)",
        "Test beta feature opt-in toggle switch application restart trigger",
        "Verify app feedback submission form with diagnostic logs attachment",
        "Validate settings configuration reset to factory default values"
    ],
    "Reports": [
        "Verify monthly sales revenue summary report export to Excel (.xlsx)",
        "Validate analytics custom date range filtering updates chart data",
        "Test scheduled PDF report generation and automated email delivery",
        "Verify user retention cohort matrix heatmap visualization accuracy",
        "Validate top-selling product category breakdown pie chart breakdown",
        "Test export order fulfillment performance metrics report to CSV",
        "Verify real-time active site visitors counter metric widget",
        "Validate customer acquisition funnel conversion rate metrics calculation",
        "Test report template saving for recurring custom analytical queries",
        "Verify average order value (AOV) trendline chart over 12 month period",
        "Validate regional sales distribution interactive map widget rendering",
        "Test server CPU and memory resource utilization audit report",
        "Verify inventory turnover velocity report with re-order threshold alerts",
        "Validate customer lifetime value (CLV) predictive model report output",
        "Test failed payment transaction root cause breakdown bar chart",
        "Verify API response latency P95 and P99 SLA compliance report",
        "Validate cart abandonment drop-off stage analysis report",
        "Test export security vulnerability scan audit findings to Excel",
        "Verify user session duration distribution histogram visualization",
        "Validate multi-touch attribution marketing campaign ROI report"
    ],
    "API": [
        "Verify REST API endpoint rate-limiting returns HTTP 429 Too Many Requests",
        "Validate OpenAPI 3.0 JSON schema validation for POST /api/v1/orders",
        "Test API request timeout handling when backend microservice delays 5s+",
        "Verify GraphQL query depth analyzer blocks nested query DOS attack vectors",
        "Validate CORS preflight OPTIONS request returns valid access headers",
        "Test REST API response content-type header is set to application/json",
        "Verify API versioning path routing (/api/v1 vs /api/v2 backward compatibility)",
        "Validate error payload format consistency returning standard JSON schema",
        "Test API payload compression handling (gzip / brotli decompression)",
        "Verify GET /api/v1/products pagination parameters limit and offset",
        "Validate API request signature verification for HMAC SHA256 webhooks",
        "Test idempotency header key processing on payment creation POST requests",
        "Verify HTTP OPTIONS endpoint returns allowed HTTP verb methods",
        "Validate handling of malformed JSON payload returning HTTP 400 Bad Request",
        "Test API response caching headers (Cache-Control, ETag, Max-Age)",
        "Verify API endpoint deprecation warning header (Sunset: date field)",
        "Validate batch API request payload processing limit (max 100 items)",
        "Test gRPC protocol buffer serialization speed for internal microservices",
        "Verify API health check endpoint /health returns status UP and DB ping",
        "Validate GraphQL mutation input sanitization against injection attacks"
    ],
    "Performance": [
        "Verify Largest Contentful Paint (LCP < 2.5s) on Simulated 3G Network",
        "Validate First Input Delay (FID < 100ms) on low-end Android mobile devices",
        "Test Cumulative Layout Shift (CLS < 0.1) during dynamic image loading",
        "Verify browser heap memory usage under continuous 2-hour stress test",
        "Validate Redis cache hit ratio exceeding 92% under 1000 concurrent VUs",
        "Test Database query execution time P95 latency remains under 50ms",
        "Verify Web Worker thread offloading for heavy pose data calculations",
        "Validate static asset CDN delivery latency under 40ms globally",
        "Test page load rendering speed with 500 DOM elements in active view",
        "Verify MediaPipe ML model execution FPS stays above 30fps on mobile",
        "Validate background worker queue throughput processing 500 jobs/sec",
        "Test WebSocket connection handshake completion time under 100ms",
        "Verify Gzip asset compression reduces payload size by at least 65%",
        "Validate browser HTTP/2 multiplexed asset request download speeds",
        "Test image asset WebP compression and responsive srcset resolution",
        "Verify cold start initialization latency of serverless AWS Lambda function",
        "Validate application memory leak checks over 100 screen transitions",
        "Test database connection pool auto-scaling under sudden spike load",
        "Verify smooth scrolling performance (sustained 60fps) on product feed",
        "Validate search index response latency during concurrent index updates"
    ],
    "Security": [
        "Verify Content Security Policy (CSP) headers block unauthorized scripts",
        "Validate HTTP Strict Transport Security (HSTS) header forces TLS 1.3",
        "Test OWASP Top 10 Broken Access Control prevention on admin endpoints",
        "Verify SQL injection payload sanitization on parameterized DB queries",
        "Validate Cross-Site Scripting (XSS) output encoding in user feedback views",
        "Test Sensitive Data Exposure check ensuring passwords are never logged",
        "Verify Secure and HttpOnly cookie flags on all session identifiers",
        "Validate API endpoints block Cross-Site Request Forgery (CSRF) attempts",
        "Test Server-Side Request Forgery (SSRF) prevention on URL fetch inputs",
        "Verify Rate-Limiting rules block DDoS flood attacks on auth routes",
        "Validate XML External Entity (XXE) injection prevention in XML parsers",
        "Test Insecure Direct Object Reference (IDOR) check on order details URL",
        "Verify Cryptographic Secret key rotation mechanism for API signing",
        "Validate CORS origin whitelist prevents untrusted origin resource fetch",
        "Test Security Header inspection (X-Frame-Options: DENY enforcement)",
        "Verify File Upload vulnerability check preventing executable PHP/shell uploads",
        "Validate User Password Hashing uses Argon2id with high memory cost",
        "Test Subresource Integrity (SRI) hash verification for external CDN scripts",
        "Verify Vulnerable Dependency scan (Trivy / Snyk) reports 0 high CVEs",
        "Validate Gitleaks secret scan confirms 0 exposed API keys in repository"
    ],
    "Mobile": [
        "Verify mobile screen rotation layout adaptation between portrait and landscape",
        "Validate swipe-to-delete gesture action performance on mobile list views",
        "Test offline mode local data caching and sync when connection restores",
        "Verify camera permission prompt request when opening QR barcode scanner",
        "Validate native FaceID and TouchID biometric authentication integration",
        "Test push notification tap event launches target screen in under 300ms",
        "Verify mobile app memory footprint remains below 150MB during active use",
        "Validate battery consumption drain rate under 3% per hour of continuous use",
        "Test mobile touch target sizing meeting 48x48dp accessibility standards",
        "Verify app state preservation when app backgrounded during form entry",
        "Validate Bluetooth LE peripheral connection handshake for hardware sensors",
        "Test mobile deep linking URI scheme opening app directly from web URL",
        "Verify native haptic feedback vibration on button click interactions",
        "Validate location permission prompt for proximity branch locator feature",
        "Test app splash screen transition speed into main dashboard screen",
        "Verify soft keyboard auto-scroll avoids overlapping focused input fields",
        "Validate app bundle size optimization keeping APK/IPA binary under 45MB",
        "Test dark mode appearance adaptation to mobile OS system theme setting",
        "Verify network status change banner display when losing cellular connection",
        "Validate back button navigation stack handling across nested screens"
    ],
    "Admin Panel": [
        "Verify super admin user account creation and RBAC role assignment",
        "Validate audit logging for system configuration setting modifications",
        "Test global maintenance mode banner activation across public storefront",
        "Verify batch user account suspension and unban action processing",
        "Validate system feature flag toggling without requiring code redeploy",
        "Test custom email template editor live HTML preview rendering",
        "Verify admin dashboard user growth analytics charts and tables",
        "Validate bulk product catalog CSV import and validation error reporting",
        "Test promo campaign creation with start date and end date schedule",
        "Verify admin IP address whitelist restriction for high-security actions",
        "Validate refund approval workflow with multi-level manager authorization",
        "Test system database backup generation and S3 cloud storage upload",
        "Verify admin user password reset dispatch from user management grid",
        "Validate merchant payout batch processing and transaction ledger export",
        "Test automated content moderation flagging inappropriate user comments",
        "Verify API key rate limit configuration per client enterprise tier",
        "Validate security audit log export to JSON and Excel formats",
        "Test system maintenance background job status monitor dashboard",
        "Verify admin panel session timeout enforcement after 10 minutes idle",
        "Validate admin dark mode theme consistency across all sub-modules"
    ]
}

def generate_excel_dataset():
    target_count = 375  # Exactly 375 test cases (between 350 and 400)
    
    # Pool all test cases and cycle/shuffle naturally
    module_indices = {m: 0 for m in modules}
    all_tests = []
    
    current_tc = 1
    mod_pointer = 0

    while len(all_tests) < target_count:
        mod = modules[mod_pointer % len(modules)]
        templates = test_templates[mod]
        idx = module_indices[mod]
        
        if idx < len(templates):
            name = templates[idx]
        else:
            # Generate additional realistic variations if index exceeds base template list
            variant_num = (idx // len(templates)) + 1
            base_template = templates[idx % len(templates)]
            name = f"{base_template} (Execution Scenario Variation #{variant_num})"
        
        module_indices[mod] += 1
        
        tc_id = f"TC_APP_{current_tc:04d}"
        
        prio = random.choices(priorities, weights=priority_weights)[0]
        status = random.choices(statuses, weights=status_weights)[0]
        
        # Duration between 0.10s and 5.00s
        duration_val = round(random.uniform(0.12, 4.95), 2)
        duration_str = f"{duration_val:.2f}s"
        
        all_tests.append({
            "id": tc_id,
            "module": mod,
            "name": name,
            "priority": prio,
            "status": status,
            "duration": duration_str,
            "duration_num": duration_val
        })
        
        current_tc += 1
        mod_pointer += 1

    # Shuffle slightly in blocks of 19 to preserve natural distribution across modules without exact repeating patterns
    final_tests = []
    chunk_size = len(modules)
    for i in range(0, len(all_tests), chunk_size):
        chunk = all_tests[i:i+chunk_size]
        random.shuffle(chunk)
        final_tests.extend(chunk)

    # Re-assign strictly sequential IDs (TC_APP_0001 to TC_APP_0375)
    for i, t in enumerate(final_tests, 1):
        t["id"] = f"TC_APP_{i:04d}"

    # Build Excel Workbook with openpyxl
    wb = openpyxl.Workbook()
    
    # Styles
    font_family = "Segoe UI"
    
    header_fill = PatternFill(start_color="1E293B", end_color="1E293B", fill_type="solid") # Dark Navy Slate
    header_font = Font(name=font_family, size=11, bold=True, color="FFFFFF")
    
    title_font = Font(name=font_family, size=16, bold=True, color="0F172A")
    subtitle_font = Font(name=font_family, size=10, italic=True, color="64748B")
    
    border_thin = Side(border_style="thin", color="CBD5E1")
    cell_border = Border(left=border_thin, right=border_thin, top=border_thin, bottom=border_thin)

    align_center = Alignment(horizontal="center", vertical="center")
    align_left = Alignment(horizontal="left", vertical="center")
    align_right = Alignment(horizontal="right", vertical="center")

    status_styles = {
        "Passed": {
            "fill": PatternFill(start_color="DCFCE7", end_color="DCFCE7", fill_type="solid"),
            "font": Font(name=font_family, size=10, bold=True, color="15803D")
        },
        "Failed": {
            "fill": PatternFill(start_color="FEE2E2", end_color="FEE2E2", fill_type="solid"),
            "font": Font(name=font_family, size=10, bold=True, color="B91C1C")
        },
        "Skipped": {
            "fill": PatternFill(start_color="FEF3C7", end_color="FEF3C7", fill_type="solid"),
            "font": Font(name=font_family, size=10, bold=True, color="B45309")
        },
        "Blocked": {
            "fill": PatternFill(start_color="F3E8FF", end_color="F3E8FF", fill_type="solid"),
            "font": Font(name=font_family, size=10, bold=True, color="6B21A8")
        }
    }

    priority_styles = {
        "Critical": Font(name=font_family, size=10, bold=True, color="DC2626"),
        "High": Font(name=font_family, size=10, bold=True, color="EA580C"),
        "Medium": Font(name=font_family, size=10, bold=False, color="0284C7"),
        "Low": Font(name=font_family, size=10, bold=False, color="475569")
    }

    # Sheet 1: Master Test Execution Report
    ws1 = wb.active
    ws1.title = "Test Execution Results"
    ws1.views.sheetView[0].showGridLines = True

    # Title Banner
    ws1.merge_cells("A1:F1")
    ws1["A1"] = "PostureFixPro Enterprise QA Test Execution Report"
    ws1["A1"].font = title_font
    ws1["A1"].alignment = align_left

    ws1.merge_cells("A2:F2")
    ws1["A2"] = "Framework: Selenium Web & Appium Mobile Automation | Environment: Staging E2E | Target: v2.4.0-RC"
    ws1["A2"].font = subtitle_font
    ws1["A2"].alignment = align_left

    # Table Headers
    headers = ["Test ID", "Module", "Test Name", "Priority", "Status", "Duration"]
    header_row = 4
    for col_idx, h in enumerate(headers, 1):
        cell = ws1.cell(row=header_row, column=col_idx, value=h)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = align_center if h in ["Test ID", "Priority", "Status", "Duration"] else align_left
        cell.border = cell_border

    # Data Rows
    start_row = 5
    for i, t in enumerate(final_tests):
        r = start_row + i
        c_id = ws1.cell(row=r, column=1, value=t["id"])
        c_mod = ws1.cell(row=r, column=2, value=t["module"])
        c_name = ws1.cell(row=r, column=3, value=t["name"])
        c_prio = ws1.cell(row=r, column=4, value=t["priority"])
        c_stat = ws1.cell(row=r, column=5, value=t["status"])
        c_dur = ws1.cell(row=r, column=6, value=t["duration"])

        c_id.alignment = align_center
        c_mod.alignment = align_left
        c_name.alignment = align_left
        c_prio.alignment = align_center
        c_stat.alignment = align_center
        c_dur.alignment = align_right

        for c in [c_id, c_mod, c_name, c_prio, c_stat, c_dur]:
            c.border = cell_border
            c.font = Font(name=font_family, size=10)

        # Apply specific priority & status styles
        if t["priority"] in priority_styles:
            c_prio.font = priority_styles[t["priority"]]

        if t["status"] in status_styles:
            c_stat.fill = status_styles[t["status"]]["fill"]
            c_stat.font = status_styles[t["status"]]["font"]

    # Adjust Column Widths
    ws1.column_dimensions['A'].width = 16
    ws1.column_dimensions['B'].width = 22
    ws1.column_dimensions['C'].width = 78
    ws1.column_dimensions['D'].width = 16
    ws1.column_dimensions['E'].width = 16
    ws1.column_dimensions['F'].width = 16

    # Sheet 2: Executive Summary Dashboard
    ws2 = wb.create_sheet(title="Executive Summary")
    ws2.views.sheetView[0].showGridLines = True

    ws2.merge_cells("A1:E1")
    ws2["A1"] = "Automated Test Suite Metrics & Summary"
    ws2["A1"].font = title_font
    ws2["A1"].alignment = align_left

    total_tests = len(final_tests)
    passed_count = sum(1 for t in final_tests if t["status"] == "Passed")
    failed_count = sum(1 for t in final_tests if t["status"] == "Failed")
    skipped_count = sum(1 for t in final_tests if t["status"] == "Skipped")
    blocked_count = sum(1 for t in final_tests if t["status"] == "Blocked")
    pass_rate = round((passed_count / total_tests) * 100, 2)
    total_duration = round(sum(t["duration_num"] for t in final_tests), 2)

    summary_data = [
        ("Total Executed Test Cases", total_tests),
        ("Passed Tests", passed_count),
        ("Failed Tests", failed_count),
        ("Skipped Tests", skipped_count),
        ("Blocked Tests", blocked_count),
        ("Overall Pass Rate (%)", f"{pass_rate}%"),
        ("Total Execution Duration (s)", f"{total_duration}s")
    ]

    ws2.cell(row=3, column=1, value="Metric").fill = header_fill
    ws2.cell(row=3, column=1).font = header_font
    ws2.cell(row=3, column=2, value="Value").fill = header_fill
    ws2.cell(row=3, column=2).font = header_font

    for idx, (m, v) in enumerate(summary_data, 4):
        c1 = ws2.cell(row=idx, column=1, value=m)
        c2 = ws2.cell(row=idx, column=2, value=v)
        c1.border = cell_border
        c2.border = cell_border
        c1.font = Font(name=font_family, size=10, bold=True)
        c2.font = Font(name=font_family, size=10, bold=True)
        c1.alignment = align_left
        c2.alignment = align_right

    ws2.column_dimensions['A'].width = 32
    ws2.column_dimensions['B'].width = 20

    # Save Excel outputs
    out_dir1 = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'Test Results', 'Excel'))
    os.makedirs(out_dir1, exist_ok=True)
    
    file_path1 = os.path.join(out_dir1, 'Enterprise_QA_Automation_Test_Report.xlsx')
    wb.save(file_path1)
    
    # Save root directory copy for easy download / portfolio visibility
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    file_path2 = os.path.join(root_dir, 'Enterprise_QA_Automation_Test_Report.xlsx')
    wb.save(file_path2)

    print(f"[SUCCESS] Generated {total_tests} enterprise QA test cases!")
    print(f"File 1: {file_path1}")
    print(f"File 2: {file_path2}")

if __name__ == "__main__":
    generate_excel_dataset()
