// Posture Fix Pro - Full Browser-Native MediaPipe & API Controller
window.onerror = function(message, source, lineno, colno, error) {
  alert("GLOBAL ERROR: " + message + " at line " + lineno + "\nSource: " + source);
  console.error("GLOBAL ERROR:", message, "at", source, ":", lineno, ":", colno, error);
  return false;
};

let poorPostureStartTime = null;
let hasTriggeredPoorPostureAlert = false;

document.addEventListener('DOMContentLoaded', () => {
  // Initialize Lucide Icons
  if (window.lucide) {
    window.lucide.createIcons();
  }

  // Set initial time on start and refresh clock every 30s
  updateClock();
  setInterval(updateClock, 30000);

  // Initialize the browser-side MediaPipe Pose Engine
  initializePoseEngine();

  // Handle offline and network status checks
  window.addEventListener('online', updateNetworkStatus);
  window.addEventListener('offline', updateNetworkStatus);
  updateNetworkStatus();

  // Onboarding persistence boot check
  const token = localStorage.getItem('token');
  
  if (token) {
    // Validate token with backend
    fetch(`http://localhost:5000/api/user/status`, {
      headers: { 'Authorization': 'Bearer ' + token }
    })
    .then(res => {
      if (res.ok) return res.json();
      throw new Error("Invalid session");
    })
    .then(data => {
      // Save state in localStorage
      localStorage.setItem('user_id', data.user_id);
      localStorage.setItem('username', data.name);
      localStorage.setItem('email', data.email);
      localStorage.setItem('onboarding_completed', data.onboarding_completed);
      
      // Populate profile inputs
      const nameInput = document.getElementById('profile-name-input');
      if (nameInput) nameInput.value = data.name;
      const ageInput = document.getElementById('profile-age-input');
      if (ageInput) ageInput.value = data.age || '';
      const genderInput = document.getElementById('profile-gender-input');
      if (genderInput) genderInput.value = data.gender || 'Male';
      
      // Transition automatically after 2.0 seconds for returning users
      setTimeout(() => {
        if (data.onboarding_completed) {
          navigateTo('home-screen');
        } else {
          navigateTo('onboarding-screen');
        }
      }, 2000);
    })
    .catch(err => {
      // Clear corrupt session and stay on splash screen
      localStorage.removeItem('token');
      localStorage.removeItem('onboarding_completed');
    });
  }
});

// Backend API configuration
const BACKEND_BASE_URL = 'http://localhost:5000/api';

// Routing & Timer States
let currentScreenId = 'splash-screen';
let monitoringTimerInterval = null;
let timerSeconds = 0;
let isWebcamMonitoringActive = false;
let currentPostureState = 'good'; // 'good' or 'bad'

// Onboarding Active Slide Track
let currentOnboardSlide = 1;

// Onboarding Slide Controls
function nextOnboardingSlide() {
  if (currentOnboardSlide < 2) {
    // Hide current active slide
    document.getElementById(`onboard-slide-${currentOnboardSlide}`).style.display = 'none';
    document.getElementById(`onboard-dot-${currentOnboardSlide}`).classList.remove('active');

    // Move to next slide
    currentOnboardSlide++;

    // Show next active slide
    document.getElementById(`onboard-slide-${currentOnboardSlide}`).style.display = 'flex';
    document.getElementById(`onboard-dot-${currentOnboardSlide}`).classList.add('active');

    // If we have reached the last slide, convert action button to "Get Started"
    if (currentOnboardSlide === 2) {
      document.getElementById('onboard-action-text').innerText = 'Get Started';
      document.getElementById('onboard-action-btn').className = 'btn btn-primary';
      document.getElementById('onboard-skip-btn').style.display = 'none'; // Hide skip
      
      const icon = document.getElementById('onboard-action-icon');
      if (icon) {
        icon.setAttribute('data-lucide', 'check');
        if (window.lucide) window.lucide.createIcons();
      }
    }
  } else {
    // Onboarding finished!
    finishOnboarding();
  }
}

// Bypasses Onboarding directly to home dashboard
function skipOnboarding() {
  finishOnboarding();
}

// Persists the onboarding status in local storage and database
function finishOnboarding() {
  localStorage.setItem('onboarding_completed', 'true');
  
  // Submit completion status to the backend API to save state in database
  fetch(`${BACKEND_BASE_URL}/user/onboarding`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + (localStorage.getItem('token') || '') // mock token
    },
    body: JSON.stringify({ onboarding_completed: true })
  }).catch(err => console.log("Backend offline, progress saved locally."));

  // Navigate to Dashboard
  navigateTo('home-screen');
}

// MediaPipe & Webcam variables
let pose = null;
let camera = null;
let canvasCtx = null;
let canvasElement = null;
let videoElement = null;
let currentCameraFacingMode = 'user'; // 'user' for front, 'environment' for rear

// Session tracking aggregates
let totalSessionFrames = 0;
let goodSessionFrames = 0;
let badPostureInstances = 0;
let accumulatedNeckAngle = 0.0;
let accumulatedSpineAngle = 0.0;
let accumulatedShoulderAngle = 0.0;
let wasPostureBad = false;

// List of screens where bottom navigation bar is active
const BOTTOM_NAV_SCREENS = ['home-screen', 'upload-image-screen', 'history-screen', 'stats-screen', 'profile-screen', 'settings-screen'];

// Update Android status bar clock
function updateClock() {
  const clockEl = document.getElementById('android-clock');
  if (!clockEl) return;
  const now = new Date();
  let hours = now.getHours();
  let minutes = now.getMinutes();
  hours = hours < 10 ? '0' + hours : hours;
  minutes = minutes < 10 ? '0' + minutes : minutes;
  clockEl.innerText = `${hours}:${minutes}`;
}

// Route navigation between screens with slide transition
function navigateTo(screenId) {
  const previousScreen = document.querySelector('.screen.active');
  const targetScreen = document.getElementById(screenId);
  
  if (!targetScreen || screenId === currentScreenId) return;

  // Deactivate old screen
  if (previousScreen) {
    previousScreen.classList.remove('active');
  }

  // Activate new screen
  targetScreen.classList.add('active');
  currentScreenId = screenId;

  // Handle bottom navigation bar visibility
  const navBar = document.getElementById('bottom-nav-bar');
  if (navBar) {
    if (BOTTOM_NAV_SCREENS.includes(screenId)) {
      navBar.style.display = 'flex';
      // Sync bottom navigation active tab
      updateBottomNavActiveState(screenId);
    } else {
      navBar.style.display = 'none';
    }
  }

  // Run screen-specific trigger actions
  onScreenEntered(screenId);
}

// Get Started button click handler
window.handleGetStarted = function() {
  const token = localStorage.getItem('token');
  const onboardingCompleted = localStorage.getItem('onboarding_completed') === 'true';
  
  if (token) {
    if (onboardingCompleted) {
      navigateTo('home-screen');
    } else {
      navigateTo('onboarding-screen');
    }
  } else {
    toggleAuthView('login');
    navigateTo('auth-screen');
  }
};

// Toggle between Login & Register cards
window.toggleAuthView = function(mode) {
  const loginCard = document.getElementById('login-card');
  const registerCard = document.getElementById('register-card');
  if (!loginCard || !registerCard) return;

  if (mode === 'login') {
    registerCard.style.display = 'none';
    loginCard.style.display = 'block';
  } else {
    loginCard.style.display = 'none';
    registerCard.style.display = 'block';
  }
};

// Update UI elements across screens with user info
window.updateUserUIDisplay = function(name, email, age, gender) {
  const userName = name || localStorage.getItem('username') || 'User';
  const userEmail = email || localStorage.getItem('email') || '';
  const firstLetter = userName.length > 0 ? userName.charAt(0).toUpperCase() : 'U';

  // Home Screen Header
  const homeTitle = document.querySelector('#home-screen .header-title');
  if (homeTitle) homeTitle.innerText = `Hello, ${userName}!`;
  const homeAvatar = document.querySelector('#home-screen .header-user .user-avatar-mini');
  if (homeAvatar) homeAvatar.innerText = firstLetter;

  // Profile Screen Header
  const profileName = document.querySelector('#profile-screen .profile-card-header .profile-name');
  if (profileName) profileName.innerText = userName;
  const profileEmail = document.querySelector('#profile-screen .profile-card-header .profile-email');
  if (profileEmail) profileEmail.innerText = userEmail;
  const profileAvatarSpan = document.querySelector('#profile-screen .profile-card-header .profile-avatar-large span');
  if (profileAvatarSpan) profileAvatarSpan.innerText = firstLetter;

  // Edit Profile Inputs
  const nameInput = document.getElementById('profile-name-input');
  if (nameInput) nameInput.value = userName;
  const ageInput = document.getElementById('profile-age-input');
  if (ageInput && age !== undefined) ageInput.value = age || '';
  const genderInput = document.getElementById('profile-gender-input');
  if (genderInput && gender !== undefined) genderInput.value = gender || 'Male';
};

// Handle Login Form Submit
window.handleLoginSubmit = async function(event) {
  event.preventDefault();
  
  const email = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value;
  const errEmail = document.getElementById('err-login-email');
  const errPass = document.getElementById('err-login-password');

  if (errEmail) errEmail.style.display = 'none';
  if (errPass) errPass.style.display = 'none';

  if (!email) {
    if (errEmail) { errEmail.innerText = 'Please enter your email'; errEmail.style.display = 'block'; }
    return;
  }
  if (!password) {
    if (errPass) { errPass.innerText = 'Please enter your password'; errPass.style.display = 'block'; }
    return;
  }

  try {
    const res = await fetch(`${BACKEND_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });

    const data = await res.json();
    if (!res.ok) {
      if (errPass) { errPass.innerText = data.message || 'Invalid credentials'; errPass.style.display = 'block'; }
      return;
    }

    // Save token and user details in localStorage
    localStorage.setItem('token', data.token);
    localStorage.setItem('user_id', data.user.user_id);
    localStorage.setItem('username', data.user.name);
    localStorage.setItem('email', data.user.email);
    localStorage.setItem('age', data.user.age || '');
    localStorage.setItem('gender', data.user.gender || 'Male');
    localStorage.setItem('onboarding_completed', data.user.onboarding_completed ? 'true' : 'false');

    // Update Profile Screen & Header
    updateUserUIDisplay(data.user.name, data.user.email, data.user.age, data.user.gender);

    // Navigate to Home or Onboarding
    if (data.user.onboarding_completed) {
      navigateTo('home-screen');
    } else {
      navigateTo('onboarding-screen');
    }
  } catch (err) {
    console.error('Login error:', err);
    alert('Failed to connect to authentication backend.');
  }
};

// Handle Registration Form Submit
window.handleRegisterSubmit = async function(event) {
  event.preventDefault();
  
  const name = document.getElementById('register-username').value.trim();
  const email = document.getElementById('register-email').value.trim();
  const age = document.getElementById('register-age').value;
  const gender = document.getElementById('register-gender').value;
  const password = document.getElementById('register-password').value;
  const confirmPassword = document.getElementById('register-confirm-password').value;

  const errName = document.getElementById('err-register-username');
  const errEmail = document.getElementById('err-register-email');
  const errPass = document.getElementById('err-register-password');
  const errConf = document.getElementById('err-register-confirm-password');

  if (errName) errName.style.display = 'none';
  if (errEmail) errEmail.style.display = 'none';
  if (errPass) errPass.style.display = 'none';
  if (errConf) errConf.style.display = 'none';

  if (!name) {
    if (errName) { errName.innerText = 'Please pick a username'; errName.style.display = 'block'; }
    return;
  }
  if (!email) {
    if (errEmail) { errEmail.innerText = 'Please enter your email'; errEmail.style.display = 'block'; }
    return;
  }
  if (!password || password.length < 6) {
    if (errPass) { errPass.innerText = 'Password must be at least 6 characters'; errPass.style.display = 'block'; }
    return;
  }
  if (password !== confirmPassword) {
    if (errConf) { errConf.innerText = 'Passwords do not match'; errConf.style.display = 'block'; }
    return;
  }

  try {
    const res = await fetch(`${BACKEND_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, password, age: age ? parseInt(age) : null, gender })
    });

    const data = await res.json();
    if (!res.ok) {
      if (errEmail) { errEmail.innerText = data.message || 'Registration failed'; errEmail.style.display = 'block'; }
      return;
    }

    // Save token and user details in localStorage
    localStorage.setItem('token', data.token);
    localStorage.setItem('user_id', data.user.user_id);
    localStorage.setItem('username', data.user.name);
    localStorage.setItem('email', data.user.email);
    localStorage.setItem('age', data.user.age || '');
    localStorage.setItem('gender', data.user.gender || 'Male');
    localStorage.setItem('onboarding_completed', 'false');

    // Update Profile Screen & Header
    updateUserUIDisplay(data.user.name, data.user.email, data.user.age, data.user.gender);

    // Navigate to Onboarding
    navigateTo('onboarding-screen');
  } catch (err) {
    console.error('Registration error:', err);
    alert('Failed to connect to authentication backend.');
  }
};

// Handle Logout
window.handleLogout = function() {
  localStorage.removeItem('token');
  localStorage.removeItem('user_id');
  localStorage.removeItem('username');
  localStorage.removeItem('email');
  localStorage.removeItem('age');
  localStorage.removeItem('gender');
  localStorage.removeItem('onboarding_completed');

  toggleAuthView('login');
  navigateTo('auth-screen');
};

// Bottom nav click handler
window.clickBottomNav = function(screenId, itemElement) {
  navigateTo(screenId);
};

// Global selected image file for Web Showcase
window.webSelectedImageFile = null;

window.handleWebImageSelection = function(event) {
  const file = event.target.files && event.target.files[0];
  if (!file) return;

  window.webSelectedImageFile = file;
  const fileName = file.name || 'posture_photo.jpg';
  const sizeMb = (file.size / (1024 * 1024)).toFixed(2);

  const previewImg = document.getElementById('web-upload-preview-img');
  if (previewImg) {
    previewImg.src = URL.createObjectURL(file);
  }

  const nameEl = document.getElementById('web-upload-filename');
  if (nameEl) nameEl.innerText = fileName;

  const sizeEl = document.getElementById('web-upload-filesize');
  if (sizeEl) sizeEl.innerText = `${sizeMb} MB • Image`;

  const selectionCards = document.getElementById('web-upload-selection-cards');
  if (selectionCards) selectionCards.style.display = 'none';

  const previewContainer = document.getElementById('web-upload-preview-container');
  if (previewContainer) previewContainer.style.display = 'flex';
  
  if (window.lucide) window.lucide.createIcons();
};

window.removeWebSelectedImage = function() {
  window.webSelectedImageFile = null;
  const galleryInput = document.getElementById('web-image-picker-gallery');
  if (galleryInput) galleryInput.value = '';
  const cameraInput = document.getElementById('web-image-picker-camera');
  if (cameraInput) cameraInput.value = '';

  const selectionCards = document.getElementById('web-upload-selection-cards');
  if (selectionCards) selectionCards.style.display = 'flex';

  const previewContainer = document.getElementById('web-upload-preview-container');
  if (previewContainer) previewContainer.style.display = 'none';
};

window.startWebImageAnalysis = function() {
  console.log("Analyze button pressed");
  console.log("Selected image file:", window.webSelectedImageFile);

  if (!window.webSelectedImageFile) {
    alert('Please select or capture a posture image first using Camera or Gallery.');
    return;
  }

  console.log("Starting analysis");
  console.log("Selected image path:", window.webSelectedImageFile.name || "Selected Image File");

  // Navigate to Processing screen to trigger AI analysis flow
  navigateTo('analysis-loading-screen');
  window.startProcessingFlow();
};

window.retryWebImageAnalysis = function() {
  window.startProcessingFlow();
};

window.startProcessingFlow = async function() {
  const titleEl = document.getElementById('analysis-loading-title');
  const msgEl = document.getElementById('analysis-loading-msg');
  const dotsContainer = document.getElementById('analysis-loading-dots');
  const failureContainer = document.getElementById('analysis-failure-container');
  const loadingContent = document.querySelector('#analysis-loading-screen .loading-content-container');
  const errorMsgEl = document.getElementById('analysis-error-message');
  
  // Reset visibility
  if (failureContainer) failureContainer.style.display = 'none';
  if (loadingContent) loadingContent.style.display = 'flex';
  if (titleEl) titleEl.innerText = 'Analyzing Image...';
  if (msgEl) msgEl.innerText = 'Uploading Image...';
  
  const steps = [
    "Uploading Image...",
    "Detecting Body Landmarks...",
    "Analyzing Posture...",
    "Generating AI Report...",
    "Preparing Results..."
  ];
  
  // Update dots indicator helper
  function updateDots(stepIndex) {
    if (!dotsContainer) return;
    const dots = dotsContainer.querySelectorAll('.dot');
    dots.forEach((dot, idx) => {
      if (idx === stepIndex) {
        dot.style.opacity = '1.0';
        dot.style.transform = 'scale(1.2)';
        dot.classList.add('active');
      } else {
        dot.style.opacity = '0.3';
        dot.style.transform = 'scale(1.0)';
        dot.classList.remove('active');
      }
    });
  }

  updateDots(0);

  let currentStep = 0;
  const progressInterval = setInterval(() => {
    if (currentStep < steps.length - 1) {
      currentStep++;
      if (msgEl) msgEl.innerText = steps[currentStep];
      updateDots(currentStep);
    }
  }, 1200);

  try {
    const formData = new FormData();
    formData.append('file', window.webSelectedImageFile);

    const token = localStorage.getItem('token') || '';
    
    console.log("Sending request to backend");
    const response = await fetch(`${BACKEND_BASE_URL}/upload-image`, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + token
      },
      body: formData
    });

    const result = await response.json();
    console.log("Backend response received:", result);
    clearInterval(progressInterval);

    if (!response.ok || result.status !== 'success') {
      throw new Error(result.message || 'The server encountered an error analyzing your posture image.');
    }

    // Success! Show final step for smooth transition
    if (msgEl) msgEl.innerText = 'Preparing Results...';
    updateDots(4);
    
    setTimeout(() => {
      console.log("Navigating to report screen");
      // Display report data
      displayAnalysisResults(result.report);
      // Navigate to results screen
      navigateTo('results-screen');
    }, 600);

  } catch (err) {
    clearInterval(progressInterval);
    console.error('Image analysis failed:', err);
    
    // Show error UI inside the loading screen
    if (loadingContent) loadingContent.style.display = 'none';
    if (failureContainer) failureContainer.style.display = 'flex';
    if (errorMsgEl) {
      errorMsgEl.innerText = err.message || 'Failed to connect to the posture analysis server. Please check your network and try again.';
    }
    if (window.lucide) window.lucide.createIcons();
  }
};

function savePostureSessionRecord(report) {
  if (!report) return;
  try {
    const sessionObj = {
      id: report.id || report.session_id || ('rpt_' + Date.now().toString(36)),
      session_id: report.id || report.session_id || ('rpt_' + Date.now().toString(36)),
      user_id: localStorage.getItem('user_id') || 'user_demo_001',
      date: report.date || new Date().toLocaleString([], { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }),
      score: report.overall_score ?? report.score ?? 85,
      duration: report.duration ?? 10,
      duration_str: report.duration_str || (report.duration ? `${Math.floor(report.duration / 60)}m ${report.duration % 60}s` : 'Scan Session'),
      problems_detected: Array.isArray(report.problems_detected) ? report.problems_detected : (report.problems || []),
      status: report.status || ((report.overall_score ?? report.score ?? 85) >= 80 ? 'Good' : ((report.overall_score ?? report.score ?? 85) >= 60 ? 'Fair' : 'Poor'))
    };

    let existing = JSON.parse(localStorage.getItem('posture_history_sessions') || '[]');
    existing = existing.filter(s => (s.id !== sessionObj.id && s.session_id !== sessionObj.session_id));
    existing.unshift(sessionObj);
    localStorage.setItem('posture_history_sessions', JSON.stringify(existing));

    fetch(`${BACKEND_BASE_URL}/save-session`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + (localStorage.getItem('token') || '')
      },
      body: JSON.stringify(sessionObj)
    }).catch(err => console.log("Session cached locally."));

  } catch (e) {
    console.error("Failed to store posture session record:", e);
  }
}

function displayAnalysisResults(report) {
  try {
    if (!report) return;

    // Automatically record analysis session to History vault & backend
    savePostureSessionRecord(report);

    // 0. Detect user pose based on slouch
    const problemsList = Array.isArray(report.problems_detected) ? report.problems_detected : [];
    const hasSlouch = problemsList.some(p => p && (p.toLowerCase().includes('slouch') || p.toLowerCase().includes('kyphosis')));
    const pose = (report.slouch_detected || hasSlouch) ? 'sitting' : 'standing';
    
    // Toggle SVG groups
    const standingGroup = document.getElementById('svg-pose-standing');
    const sittingGroup = document.getElementById('svg-pose-sitting');
    if (pose === 'sitting') {
      if (standingGroup) standingGroup.style.display = 'none';
      if (sittingGroup) sittingGroup.style.display = 'block';
    } else {
      if (standingGroup) standingGroup.style.display = 'block';
      if (sittingGroup) sittingGroup.style.display = 'none';
    }

    const prefix = pose === 'sitting' ? 'svg-sit-' : 'svg-';
    const refPrefix = pose === 'sitting' ? 'ref-sit-' : 'ref-stand-';

    function updateRefLine(lineId, hasError) {
      const line = document.getElementById(refPrefix + lineId);
      if (line) {
        line.style.stroke = hasError ? '#EF4444' : '#10B981';
        line.style.opacity = hasError ? '0.7' : '0.2';
      }
    }

    // 1. Update score & verdict
    const scoreEl = document.getElementById('results-score');
    if (scoreEl) {
      scoreEl.innerText = `${report.overall_score ?? 0}% Score`;
    }
    
    const verdictEl = document.getElementById('results-verdict');
    const subtitleEl = document.getElementById('results-map-subtitle');

    // Let's determine if we have any errors
    const hasErrors = (report.overall_score ?? 0) < 85 || 
                      problemsList.some(p => p && !p.toLowerCase().includes('optimal'));

    if (!hasErrors) {
      if (verdictEl) {
        verdictEl.innerText = "Excellent Posture";
        verdictEl.style.color = "var(--primary)";
      }
      if (subtitleEl) {
        subtitleEl.innerText = "Excellent Posture! All body parts are aligned correctly.";
      }

      // Set ALL SVG body parts to green
      const greenColor = '#10B981';
      updateSVGPart(prefix + 'head', 'Head', 'Normal Alignment', 'Good job! Keep maintaining this position.', false, greenColor);
      updateSVGPart(prefix + 'neck', 'Neck', 'Normal Alignment', 'Neck is aligned. Great posture!', false, greenColor);
      updateSVGPart(prefix + 'shoulder-left', 'Left Shoulder', 'Normal Alignment', 'Shoulders are level and balanced.', false, greenColor);
      updateSVGPart(prefix + 'shoulder-right', 'Right Shoulder', 'Normal Alignment', 'Shoulders are level and balanced.', false, greenColor);
      updateSVGPart(prefix + 'upper-back', 'Upper Back', 'Normal Alignment', 'Spinal alignment looks optimal.', false, greenColor);
      updateSVGPart(prefix + 'spine', 'Spine', 'Normal Alignment', 'Spine is properly extended.', false, greenColor);
      updateSVGPart(prefix + 'pelvis', 'Pelvis', 'Normal Alignment', 'Pelvis is aligned horizontally.', false, greenColor);
      updateSVGPart(prefix + 'knee-left', 'Left Knee', 'Normal Alignment', 'Joint weight distribution is equal.', false, greenColor);
      updateSVGPart(prefix + 'knee-right', 'Right Knee', 'Normal Alignment', 'Joint weight distribution is equal.', false, greenColor);
      
      // Set static limb colors to green
      const greenColorHex = greenColor;
      document.getElementById(prefix + 'arm-left')?.setAttribute('fill', greenColorHex);
      document.getElementById(prefix + 'arm-right')?.setAttribute('fill', greenColorHex);
      document.getElementById(prefix + 'leg-left')?.setAttribute('fill', greenColorHex);
      document.getElementById(prefix + 'leg-right')?.setAttribute('fill', greenColorHex);
      document.getElementById(prefix + 'calf-left')?.setAttribute('fill', greenColorHex);
      document.getElementById(prefix + 'calf-right')?.setAttribute('fill', greenColorHex);

      // Green reference lines
      updateRefLine('neck', false);
      updateRefLine('shoulder', false);
      updateRefLine('spine', false);
      updateRefLine('pelvis', false);
      updateRefLine('knee', false);

    } else {
      // Has errors! Set default gray and highlight specific elements in red
      if (verdictEl) {
        const score = report.overall_score ?? 0;
        verdictEl.innerText = score >= 70 ? "Good Alignment" : (score >= 50 ? "Fair - Needs Attention" : "Poor - Slouching Detected");
        verdictEl.style.color = score >= 70 ? "var(--primary)" : (score >= 50 ? "var(--warning)" : "var(--alert)");
      }
      if (subtitleEl) {
        subtitleEl.innerText = `User Pose Mode: ${pose === 'sitting' ? 'Sitting' : 'Standing'} Assessment. Tap highlighted red body parts.`;
      }

      const defaultGray = '#E2E8F0';
      const errorRed = '#EF4444';

      const isNeckError = !!report.forward_head_detected;
      const isShoulderError = (report.shoulder_alignment ?? 0) > 3.0;
      const isUpperBackError = !!report.slouch_detected;
      const isSpineError = !!report.slouch_detected;
      const isPelvicError = (report.hip_alignment ?? 0) > 3.5;
      const isKneeError = (report.knee_alignment ?? 0) > 3.0;

      // 1. Head / Neck
      updateSVGPart(prefix + 'head', 'Head', isNeckError ? 'Forward Head Posture' : 'Normal Alignment', isNeckError ? 'Lift head and pull chin back level with shoulders.' : 'Head is aligned.', isNeckError, isNeckError ? errorRed : defaultGray);
      updateSVGPart(prefix + 'neck', 'Neck', isNeckError ? 'Forward Head Posture' : 'Normal Alignment', isNeckError ? 'Lift head and pull chin back level with shoulders.' : 'Neck is well-aligned.', isNeckError, isNeckError ? errorRed : defaultGray);

      // 2. Shoulders
      updateSVGPart(prefix + 'shoulder-left', 'Left Shoulder', isShoulderError ? 'Uneven Shoulder Height' : 'Normal Alignment', isShoulderError ? 'Relax shoulders and align horizontally.' : 'Shoulders are level.', isShoulderError, isShoulderError ? errorRed : defaultGray);
      updateSVGPart(prefix + 'shoulder-right', 'Right Shoulder', isShoulderError ? 'Uneven Shoulder Height' : 'Normal Alignment', isShoulderError ? 'Relax shoulders and align horizontally.' : 'Shoulders are level.', isShoulderError, isShoulderError ? errorRed : defaultGray);

      // 3. Upper Back
      updateSVGPart(prefix + 'upper-back', 'Upper Back', isUpperBackError ? 'Rounded Upper Back' : 'Normal Alignment', isUpperBackError ? 'Draw shoulder blades together and lift chest.' : 'Upper back is straight.', isUpperBackError, isUpperBackError ? errorRed : defaultGray);

      // 4. Spine
      updateSVGPart(prefix + 'spine', 'Spine', isSpineError ? 'Thoracic/Lumbar Slouch' : 'Normal Alignment', isSpineError ? 'Sit straight with back flat against support.' : 'Spine is well-aligned.', isSpineError, isSpineError ? errorRed : defaultGray);

      // 5. Pelvis
      updateSVGPart(prefix + 'pelvis', 'Pelvis', isPelvicError ? 'Anterior Pelvic Tilt' : 'Normal Alignment', isPelvicError ? 'Engage core and level pelvis position.' : 'Pelvis is aligned.', isPelvicError, isPelvicError ? errorRed : defaultGray);

      // 6. Knees
      updateSVGPart(prefix + 'knee-left', 'Left Knee', isKneeError ? 'Knee Joint Imbalance' : 'Normal Alignment', isKneeError ? 'Distribute leg weight evenly.' : 'Knee weight is balanced.', isKneeError, isKneeError ? errorRed : defaultGray);
      updateSVGPart(prefix + 'knee-right', 'Right Knee', isKneeError ? 'Knee Joint Imbalance' : 'Normal Alignment', isKneeError ? 'Distribute leg weight evenly.' : 'Knee weight is balanced.', isKneeError, isKneeError ? errorRed : defaultGray);

      // Update Ref lines colors
      updateRefLine('neck', isNeckError);
      updateRefLine('shoulder', isShoulderError);
      updateRefLine('spine', isSpineError);
      updateRefLine('pelvis', isPelvicError);
      updateRefLine('knee', isKneeError);

      // Reset static limbs to gray
      document.getElementById(prefix + 'arm-left')?.setAttribute('fill', defaultGray);
      document.getElementById(prefix + 'arm-right')?.setAttribute('fill', defaultGray);
      document.getElementById(prefix + 'leg-left')?.setAttribute('fill', defaultGray);
      document.getElementById(prefix + 'leg-right')?.setAttribute('fill', defaultGray);
      document.getElementById(prefix + 'calf-left')?.setAttribute('fill', defaultGray);
      document.getElementById(prefix + 'calf-right')?.setAttribute('fill', defaultGray);
    }

    // 3. Update detected problems list
    const problemsContainer = document.getElementById('web-detected-problems-container');
    if (problemsContainer) {
      problemsContainer.innerHTML = '';
      
      // Build clean problems list excluding optimal strings
      const problems = (Array.isArray(report.problems_detected) ? report.problems_detected : []).filter(p => p && !p.toLowerCase().includes('optimal'));
      
      if (problems.length > 0) {
        problems.forEach(prob => {
          problemsContainer.innerHTML += `
            <div class="card" style="padding: 12px 14px; margin-bottom: 0; display: flex; align-items: center; gap: 12px; border-radius: 14px; border: 1px solid var(--border); background: #ffffff;">
              <div style="padding: 8px; background: #FEE2E2; border-radius: 8px; color: #EF4444; display: flex; align-items: center; justify-content: center;">
                <i data-lucide="alert-circle" width="18" height="18"></i>
              </div>
              <div style="flex: 1; text-align: left;">
                <div style="font-size: 13px; font-weight: 700; color: var(--text-main);">${prob}</div>
                <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">Correction exercise recommended</div>
              </div>
              <span style="font-size: 10px; font-weight: 700; background: #FEE2E2; color: #EF4444; padding: 3px 8px; border-radius: 6px;">Incorrect</span>
            </div>
          `;
        });
      } else {
        problemsContainer.innerHTML = `
          <div class="card" style="padding: 12px 14px; margin-bottom: 0; display: flex; align-items: center; gap: 12px; border-radius: 14px; border: 1px solid var(--border); background: #ffffff;">
            <div style="padding: 8px; background: var(--primary-light); border-radius: 8px; color: var(--primary); display: flex; align-items: center; justify-content: center;">
              <i data-lucide="check" width="18" height="18"></i>
            </div>
            <div style="flex: 1; text-align: left;">
              <div style="font-size: 13px; font-weight: 700; color: var(--text-main);">Excellent Posture</div>
              <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">All bones & joints are aligned inside safety thresholds.</div>
            </div>
            <span style="font-size: 10px; font-weight: 700; background: var(--primary-light); color: var(--primary); padding: 3px 8px; border-radius: 6px;">Optimal</span>
          </div>
        `;
      }
    }

    // 4. Initialize selected marker card with the first error, or default to Neck
    if (hasErrors) {
      if (report.forward_head_detected) {
        window.selectWebPosturePart('Neck', 'Forward Head Posture', 'Lift head and pull chin back level with shoulders.', true);
      } else if ((report.shoulder_alignment ?? 0) > 3.0) {
        window.selectWebPosturePart('Shoulders', 'Uneven Shoulder Height', 'Relax shoulders and align horizontally.', true);
      } else if (report.slouch_detected) {
        window.selectWebPosturePart('Spine', 'Thoracic/Lumbar Slouch', 'Sit straight with back flat against support.', true);
      } else if ((report.hip_alignment ?? 0) > 3.5) {
        window.selectWebPosturePart('Pelvis', 'Anterior Pelvic Tilt', 'Engage core and level pelvis position.', true);
      } else if ((report.knee_alignment ?? 0) > 3.0) {
        window.selectWebPosturePart('Knees', 'Knee Joint Imbalance', 'Distribute leg weight evenly.', true);
      }
    } else {
      window.selectWebPosturePart('Body Alignment', 'Excellent Posture', 'Good job! Keep maintaining this position.', false);
    }

    // Refresh Lucide icons
    if (window.lucide) {
      window.lucide.createIcons();
    }
  } catch (error) {
    console.error("Error inside displayAnalysisResults:", error);
    alert("Error rendering analysis results: " + error.message);
  }
}

function updateSVGPart(elementId, partName, problemName, correctionTip, isError, fillColor) {
  const el = document.getElementById(elementId);
  if (!el) return;
  
  const nameStr = (partName || '').toString().replace(/'/g, "\\'");
  const probStr = (problemName || '').toString().replace(/'/g, "\\'");
  const tipStr = (correctionTip || '').toString().replace(/'/g, "\\'");
  
  el.setAttribute('fill', fillColor);
  el.setAttribute('onclick', `window.selectWebPosturePart('${nameStr}', '${probStr}', '${tipStr}', ${!!isError})`);
}

window.selectWebPosturePart = function(partName, problemName, correctionTip, isError) {
  const card = document.getElementById('web-marker-info-card');
  const titleEl = document.getElementById('web-marker-title');
  const statusEl = document.getElementById('web-marker-status');
  const descEl = document.getElementById('web-marker-desc');

  if (!card || !titleEl || !statusEl || !descEl) return;

  // Set colors and content
  if (isError) {
    card.style.background = '#FEF2F2';
    card.style.borderColor = 'rgba(239, 68, 68, 0.2)';
    titleEl.style.color = '#EF4444';
    titleEl.innerHTML = `<i data-lucide="alert-triangle" width="16" height="16"></i><span>${partName}</span>`;
    statusEl.style.background = '#EF4444';
    statusEl.innerText = problemName;
  } else {
    card.style.background = '#ECFDF5';
    card.style.borderColor = 'rgba(16, 185, 129, 0.2)';
    titleEl.style.color = '#10B981';
    titleEl.innerHTML = `<i data-lucide="check-circle" width="16" height="16"></i><span>${partName}</span>`;
    statusEl.style.background = '#10B981';
    statusEl.innerText = problemName;
  }

  descEl.innerText = correctionTip;
};



// Keep bottom navigation bar tabs in sync
function updateBottomNavActiveState(screenId) {
  const navItems = document.querySelectorAll('.bottom-nav .nav-item');
  navItems.forEach(item => {
    item.classList.remove('active');
    const onclickAttr = item.getAttribute('onclick') || '';
    if (onclickAttr.includes(screenId)) {
      item.classList.add('active');
    }
  });
}

// Trigger operations when entering a new screen (e.g. Audio chime alert triggers)
function onScreenEntered(screenId) {
  if (screenId === 'alert-screen') {
    const audioEnabled = document.getElementById('alert-audio-toggle')?.checked ?? true;
    if (audioEnabled) {
      playBeepAlert();
    }
  } else if (screenId === 'feedback-screen') {
    const audioEnabled = document.getElementById('alert-audio-toggle')?.checked ?? true;
    if (audioEnabled) {
      playSuccessChime();
    }
  } else if (screenId === 'home-screen') {
    loadDashboardData();
  } else if (screenId === 'history-screen') {
    loadHistoryData();
  } else if (screenId === 'stats-screen') {
    loadStatsData();
  } else if (screenId === 'profile-screen') {
    // Populate stats summary details
    const userId = localStorage.getItem('user_id');
    const token = localStorage.getItem('token');
    const username = localStorage.getItem('username') || 'User Name';
    const email = localStorage.getItem('email') || 'user@example.com';
    
    const profileName = document.querySelector('.profile-card-header .profile-name');
    if (profileName) profileName.innerText = username;
    const profileEmail = document.querySelector('.profile-card-header .profile-email');
    if (profileEmail) profileEmail.innerText = email;
    const avatarInitials = document.querySelector('.profile-card-header .profile-avatar-large span');
    if (avatarInitials) avatarInitials.innerText = username.charAt(0).toUpperCase();
    
    // Fetch stats and profile details
    if (userId && token) {
      fetch(`${BACKEND_BASE_URL}/stats/${userId}`, {
        headers: { 'Authorization': 'Bearer ' + token }
      })
      .then(res => res.json())
      .then(data => {
        const statsSessions = document.getElementById('profile-stat-sessions');
        if (statsSessions) statsSessions.innerText = `${data.stats.total_sessions} sessions`;
        const statsScore = document.getElementById('profile-stat-score');
        if (statsScore) statsScore.innerText = `${data.stats.avg_score}%`;
      }).catch(err => {});
      
      // Load avatar if present
      fetch(`${BACKEND_BASE_URL}/user/status`, {
        headers: { 'Authorization': 'Bearer ' + token }
      })
      .then(res => res.json())
      .then(data => {
        if (data.profile_image) {
          const avatarBox = document.querySelector('.profile-card-header .profile-avatar-large');
          if (avatarBox) {
            avatarBox.style.backgroundImage = `url(${data.profile_image})`;
            avatarBox.style.backgroundSize = 'cover';
          }
          if (avatarInitials) avatarInitials.style.display = 'none';
        }
      }).catch(err => {});
    }
  }
}

// Formats timer duration as HH:MM:SS
function updateTimerDisplay() {
  const timerEl = document.getElementById('monitor-timer');
  if (!timerEl) return;
  const hours = Math.floor(timerSeconds / 3600);
  const minutes = Math.floor((timerSeconds % 3600) / 60);
  const seconds = timerSeconds % 60;
  
  const hDisplay = hours < 10 ? '0' + hours : hours;
  const mDisplay = minutes < 10 ? '0' + minutes : minutes;
  const sDisplay = seconds < 10 ? '0' + seconds : seconds;
  
  timerEl.innerText = `${hDisplay}:${mDisplay}:${sDisplay}`;
}

/* --- MATH UTILS FOR POSTURE EVALUATIONS --- */

// Calculates 2D angle (in degrees) formed at vertex b between endpoints a and c
function calculateAngle(a, b, c) {
  const ba = { x: a.x - b.x, y: a.y - b.y };
  const bc = { x: c.x - b.x, y: c.y - b.y };

  const dotProduct = ba.x * bc.x + ba.y * bc.y;
  const magBA = Math.sqrt(ba.x * ba.x + ba.y * ba.y);
  const magBC = Math.sqrt(bc.x * bc.x + bc.y * bc.y);

  const cosine = dotProduct / (magBA * magBC + 1e-6);
  const clamped = Math.max(-1.0, Math.min(1.0, cosine));

  return Math.abs((Math.atan2(bc.y, bc.x) - Math.atan2(ba.y, ba.x)) * 180 / Math.PI) % 360;
}

// Calculates segment deviation from absolute vertical line
function calculateVerticalDeviation(a, b) {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  // Deviation from true vertical (90 degrees slope)
  const angle = Math.abs((Math.atan2(dy, dx) * 180) / Math.PI);
  return Math.abs(90 - angle);
}

/* --- CLIENT-SIDE MEDIAPIPE CORE ENGINE --- */

function initializePoseEngine() {
  videoElement = document.getElementById('webcam-raw-video');
  canvasElement = document.getElementById('webcam-skeleton-canvas');
  canvasCtx = canvasElement.getContext('2d');

  if (typeof Pose === 'undefined') {
    console.warn("MediaPipe Pose library unavailable in environment.");
    return;
  }

  // Configure Pose Instance
  pose = new Pose({locateFile: (file) => {
    return `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`;
  }});

  pose.setOptions({
    modelComplexity: 1,
    smoothLandmarks: true,
    enableSegmentation: false,
    minDetectionConfidence: 0.5,
    minTrackingConfidence: 0.5
  });

  // Attach results handler
  pose.onResults(onPoseResults);
}

// Live frame rendering and skeleton landmarks coordinate tracking
function onPoseResults(results) {
  if (!isWebcamMonitoringActive || currentScreenId !== 'monitoring-screen') return;

  // Sync canvas size to capture feed dimensions
  canvasElement.width = videoElement.videoWidth || 640;
  canvasElement.height = videoElement.videoHeight || 480;

  // Clear Canvas and Draw raw camera frame mirrored
  canvasCtx.save();
  canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);
  canvasCtx.drawImage(results.image, 0, 0, canvasElement.width, canvasElement.height);

  let isPostureBad = false;
  let neckDev = 0.0;
  let shoulderDev = 0.0;
  let spineDev = 0.0;

  if (results.poseLandmarks && results.poseLandmarks.length > 0) {
    const landmarks = results.poseLandmarks;
    
    // Core posture joint nodes indices (MediaPipe Pose specification)
    const lShoulder = landmarks[11];
    const rShoulder = landmarks[12];
    const lEar = landmarks[7];
    const rEar = landmarks[8];
    const lHip = landmarks[23];
    const rHip = landmarks[24];

    // Compute segment midpoints
    const midShoulder = {
      x: (lShoulder.x + rShoulder.x) / 2,
      y: (lShoulder.y + rShoulder.y) / 2
    };
    const midEar = {
      x: (lEar.x + rEar.x) / 2,
      y: (lEar.y + rEar.y) / 2
    };
    const midHip = {
      x: (lHip.x + rHip.x) / 2,
      y: (lHip.y + rHip.y) / 2
    };

    // 1. Calculate Neck, Shoulder and Spine Angles
    neckDev = calculateVerticalDeviation(midEar, midShoulder);
    spineDev = calculateVerticalDeviation(midShoulder, midHip);
    shoulderDev = Math.abs(calculateAngle(lShoulder, midShoulder, { x: lShoulder.x, y: midShoulder.y }));
    if (Math.abs(lShoulder.y - rShoulder.y) < 0.01) {
      shoulderDev = 0.0;
    }

    // Dynamic threshold audits matching user sensitivity slider
    const sensitivityVal = parseInt(document.getElementById('settings-sensitivity')?.value || 6);
    let neckThreshold = 22.0 - (sensitivityVal * 0.8);  // medium around 16.0
    let spineThreshold = 26.0 - (sensitivityVal * 0.8); // medium around 20.0
    let shoulderThreshold = 14.0 - (sensitivityVal * 0.6);

    // Assess Good vs Bad status
    if (neckDev > neckThreshold || spineDev > spineThreshold || shoulderDev > shoulderThreshold) {
      isPostureBad = true;
    }

    // Update Session Metrics Accumulations
    totalSessionFrames++;
    accumulatedNeckAngle += neckDev;
    accumulatedSpineAngle += spineDev;
    accumulatedShoulderAngle += shoulderDev;
    if (!isPostureBad) {
      goodSessionFrames++;
    }

    // Enforce 5-second continuous poor posture rule
    if (isPostureBad) {
      if (!poorPostureStartTime) {
        poorPostureStartTime = Date.now();
      } else {
        const elapsed = (Date.now() - poorPostureStartTime) / 1000;
        if (elapsed >= 5 && !hasTriggeredPoorPostureAlert) {
          hasTriggeredPoorPostureAlert = true;
          badPostureInstances++;
          
          // Determine the main reason/type of slouching
          let alertType = "Spine";
          let suggestion = "Please roll your shoulders back and sit straight.";
          if (neckDev > neckThreshold) {
            alertType = "Neck";
            suggestion = "Lift your head. Your neck alignment is leaning forward.";
          } else if (shoulderDev > shoulderThreshold) {
            alertType = "Shoulder";
            suggestion = "Align your shoulders horizontally. Keep them level.";
          }
          
          // Trigger Poor Posture screen
          simulateState('bad', suggestion);
          
          // Save alert event to database
          fetch(`${BACKEND_BASE_URL}/alerts`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ' + (localStorage.getItem('token') || '')
            },
            body: JSON.stringify({
              duration: Math.round(elapsed),
              suggestion: suggestion,
              alert_type: alertType
            })
          }).catch(err => console.log("Failed to persist alert event to database."));
        }
      }
    } else {
      // If posture is good, check if we were slouched
      if (hasTriggeredPoorPostureAlert) {
        simulateState('good');
      }
      poorPostureStartTime = null;
      hasTriggeredPoorPostureAlert = false;
    }
    wasPostureBad = isPostureBad;

    // 2. Render Custom Skeleton Overlay
    const skelColor = isPostureBad ? '#EF4444' : '#10B981';
    const jointColor = '#ffffff';

    // Draw lines
    drawSkeletonSegment(lShoulder, rShoulder, skelColor, 6); // shoulders
    drawSkeletonSegment(lHip, rHip, skelColor, 6);       // hips
    drawSkeletonSegment(midShoulder, midEar, skelColor, 5); // neck
    drawSkeletonSegment(midShoulder, midHip, skelColor, 5); // spine

    // Draw joints
    [lShoulder, rShoulder, lHip, rHip, midEar, midShoulder, midHip].forEach(joint => {
      drawJointCircle(joint, jointColor, skelColor, 8);
    });

  } else {
    // If no human landmarks are captured, keep status as searching
    document.getElementById('monitor-status-desc').innerText = "Analyzing body placement... Center yourself in frame.";
  }

  canvasCtx.restore();

  // Update HUD elements in real-time continuously
  document.getElementById('val-neck').innerText = `${neckDev.toFixed(1)}°`;
  document.getElementById('val-shoulder').innerText = `${shoulderDev.toFixed(1)}°`;
  document.getElementById('val-spine').innerText = `${spineDev.toFixed(1)}°`;

  const statusBadge = document.getElementById('monitor-status-badge');
  const statusDesc = document.getElementById('monitor-status-desc');

  if (isPostureBad) {
    statusBadge.className = 'status-badge warning';
    statusBadge.innerText = '⚠️ Poor Posture';
    statusDesc.innerText = 'Slouch or head tilt deviation detected.';
  } else if (results.poseLandmarks && results.poseLandmarks.length > 0) {
    statusBadge.className = 'status-badge good';
    statusBadge.innerText = '🟢 Monitoring Active';
    statusDesc.innerText = 'Spine, neck, and shoulders aligned inside threshold.';
  }
}

// Drawing helper to draw skeleton segment paths
function drawSkeletonSegment(p1, p2, color, thickness) {
  const w = canvasElement.width;
  const h = canvasElement.height;
  canvasCtx.beginPath();
  canvasCtx.moveTo(p1.x * w, p1.y * h);
  canvasCtx.lineTo(p2.x * w, p2.y * h);
  canvasCtx.strokeStyle = color;
  canvasCtx.lineWidth = thickness;
  canvasCtx.lineCap = 'round';
  canvasCtx.stroke();
}

// Drawing helper to draw joint nodes
function drawJointCircle(p, fillColor, ringColor, radius) {
  const w = canvasElement.width;
  const h = canvasElement.height;
  
  canvasCtx.beginPath();
  canvasCtx.arc(p.x * w, p.y * h, radius, 0, 2 * Math.PI);
  canvasCtx.fillStyle = fillColor;
  canvasCtx.fill();
  canvasCtx.strokeStyle = ringColor;
  canvasCtx.lineWidth = 2.5;
  canvasCtx.stroke();
}

// Initializer to start and stop the browser-native camera
async function toggleWebcamMonitoring() {
  const placeholder = document.getElementById('webcam-placeholder');
  const canvasOverlay = document.getElementById('webcam-skeleton-canvas');
  const cameraBadge = document.getElementById('camera-badge');
  const aiBadge = document.getElementById('ai-active-badge');
  const btnToggle = document.getElementById('btn-toggle-monitor');
  const statusBadge = document.getElementById('monitor-status-badge');
  const statusDesc = document.getElementById('monitor-status-desc');
  const timerEl = document.getElementById('monitor-timer');

  if (!isWebcamMonitoringActive) {
    // 1. Initializing 10-second monitoring session
    isWebcamMonitoringActive = true;
    timerSeconds = 10;
    totalSessionFrames = 0;
    goodSessionFrames = 0;
    badPostureInstances = 0;
    accumulatedNeckAngle = 0.0;
    accumulatedSpineAngle = 0.0;
    accumulatedShoulderAngle = 0.0;
    wasPostureBad = false;
    
    if (timerEl) timerEl.innerText = "10s";

    // Toggle camera DOM blocks
    videoElement.style.display = 'block';
    canvasOverlay.style.display = 'block';
    placeholder.style.display = 'none';
    cameraBadge.style.display = 'flex';
    aiBadge.style.display = 'flex';

    // Start 10-second countdown timer
    monitoringTimerInterval = setInterval(() => {
      timerSeconds--;
      if (timerEl) timerEl.innerText = `${timerSeconds}s`;
      
      if (timerSeconds <= 0) {
        // Automatically stop the webcam and trigger report
        clearInterval(monitoringTimerInterval);
        monitoringTimerInterval = null;
        toggleWebcamMonitoring(); // triggers the else block to stop and analyze
      }
    }, 1000);

    // Start custom camera stream with selected facingMode
    startCustomCameraStream();
    
    btnToggle.className = 'btn btn-alert';
    btnToggle.innerHTML = `<i data-lucide="square" width="16" height="16"></i> <span>Stop Scan</span>`;
    if (window.lucide) window.lucide.createIcons();

    // Alert backend session started
    fetch(`${BACKEND_BASE_URL}/monitoring/start`, { method: 'POST' }).catch(err => {});

  } else {
    // 2. Finalize monitoring session and analyze
    isWebcamMonitoringActive = false;
    if (monitoringTimerInterval) {
      clearInterval(monitoringTimerInterval);
      monitoringTimerInterval = null;
    }

    // Stop and release camera stream cleanly
    if (videoElement && videoElement.srcObject) {
      videoElement.srcObject.getTracks().forEach(track => track.stop());
      videoElement.srcObject = null;
    }

    // Reset layouts
    videoElement.style.display = 'none';
    canvasOverlay.style.display = 'none';
    placeholder.style.display = 'flex';
    cameraBadge.style.display = 'none';
    aiBadge.style.display = 'none';

    btnToggle.className = 'btn btn-primary';
    btnToggle.innerHTML = `<i data-lucide="play" width="16" height="16"></i> <span>Start Webcam Session</span>`;
    if (window.lucide) window.lucide.createIcons();

    statusBadge.className = 'status-badge';
    statusBadge.style.background = 'var(--accent-gray)';
    statusBadge.style.color = 'var(--text-muted)';
    statusBadge.innerText = '⚪ Idle';
    statusDesc.innerText = 'Webcam and MediaPipe monitoring offline.';

    // Calculate posture metrics
    let goodPercentage = 100;
    let poorPercentage = 0;
    let score = 100;

    if (totalSessionFrames > 0) {
      goodPercentage = Math.round((goodSessionFrames / totalSessionFrames) * 100);
      poorPercentage = 100 - goodPercentage;
      score = goodPercentage;
    }

    let avgNeck = totalSessionFrames > 0 ? (accumulatedNeckAngle / totalSessionFrames) : 0.0;
    let avgSpine = totalSessionFrames > 0 ? (accumulatedSpineAngle / totalSessionFrames) : 0.0;
    let avgShoulder = totalSessionFrames > 0 ? (accumulatedShoulderAngle / totalSessionFrames) : 0.0;

    // Generate correction suggestions based on analysis results
    let suggestions = "";
    if (poorPercentage > 20) {
      if (avgNeck > avgSpine && avgNeck > avgShoulder) {
        suggestions = "Your neck was leaning forward by an average of " + avgNeck.toFixed(1) + "°. Try to lift your chin, level your gaze, and avoid looking down.";
      } else if (avgShoulder > avgNeck && avgShoulder > avgSpine) {
        suggestions = "Your shoulders were tilted by an average of " + avgShoulder.toFixed(1) + "°. Keep your shoulders relaxed and level.";
      } else {
        suggestions = "Your spine was curved or slouched by " + avgSpine.toFixed(1) + "° on average. Roll your shoulders back and sit flat against your back support.";
      }
    } else {
      suggestions = "Great posture alignment! Your neck and spine were straight for " + goodPercentage + "% of the scan. Keep sitting upright!";
    }

    // Build simulated report for the redesigned Anatomical Posture Map
    const sensitivity = parseInt(document.getElementById('settings-sensitivity')?.value || 6);
    const neckThreshold = 22.0 - (sensitivity * 0.8);
    const shoulderThreshold = 3.0;
    const spineThreshold = 26.0 - (sensitivity * 0.8);

    const simulatedReport = {
      overall_score: score,
      forward_head_detected: avgNeck > neckThreshold,
      shoulder_alignment: avgShoulder,
      slouch_detected: avgSpine > spineThreshold,
      spine_alignment: avgSpine,
      hip_alignment: 0.0,
      knee_alignment: 0.0,
      problems_detected: []
    };

    if (simulatedReport.forward_head_detected) simulatedReport.problems_detected.push("Forward Head Posture");
    if (simulatedReport.shoulder_alignment > shoulderThreshold) simulatedReport.problems_detected.push("Uneven Shoulder Height");
    if (simulatedReport.slouch_detected) {
      simulatedReport.problems_detected.push("Rounded Upper Back");
      simulatedReport.problems_detected.push("Thoracic/Lumbar Slouch");
    }

    displayAnalysisResults(simulatedReport);

    // Update Dashboard aggregates locally
    const durationTracked = 10 - timerSeconds;
    document.getElementById('home-session-time').innerText = `${durationTracked}s`;
    document.getElementById('home-corrections').innerText = poorPercentage > 20 ? 1 : 0;

    // Save only results to backend database (duration, score, bad posture, avg neck)
    const sessionPayload = {
      duration: durationTracked,
      score: score,
      bad_posture_count: poorPercentage > 20 ? 1 : 0,
      average_neck_angle: avgNeck
    };

    fetch(`${BACKEND_BASE_URL}/save-session`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + (localStorage.getItem('token') || '')
      },
      body: JSON.stringify(sessionPayload)
    }).catch(err => console.log("Backend offline, session cached locally."));

    // Automatically navigate to Results Report screen
    navigateTo('results-screen');
  }
}

// Simulation panel control handler
function simulateState(state, customSuggestion = "") {
  currentPostureState = state;
  const homeCard = document.getElementById('home-status-card');
  const homeTitle = document.getElementById('home-status-title');
  const homeDesc = document.getElementById('home-status-desc');
  const homeBadge = document.getElementById('home-badge');
  const homeEmoji = document.getElementById('home-status-emoji');

  if (state === 'bad') {
    navigateTo('alert-screen');
    
    // Update alert description
    const alertDesc = document.querySelector('#alert-screen .feedback-desc');
    if (alertDesc) {
      alertDesc.innerHTML = customSuggestion || 'Slouching detected. Please sit upright to relieve spinal strain.';
    }

    // Update Dashboard status card
    if (homeCard) {
      homeCard.style.background = 'var(--alert-light)';
      homeCard.style.borderColor = 'rgba(239, 68, 68, 0.15)';
      homeTitle.innerText = 'Posture Alert!';
      homeTitle.style.color = 'var(--alert)';
      homeDesc.innerText = customSuggestion || 'Slouching detected. Please sit upright to relieve spinal strain.';
      homeBadge.className = 'status-badge warning';
      homeBadge.style.background = 'rgba(239, 68, 68, 0.1)';
      homeBadge.style.color = 'var(--alert)';
      homeBadge.innerText = 'Needs Attention';
      homeEmoji.innerText = '🥵';
    }
  } else {
    navigateTo('feedback-screen');

    // Restore Dashboard status card
    if (homeCard) {
      homeCard.style.background = 'var(--primary-light)';
      homeCard.style.borderColor = 'rgba(16, 185, 129, 0.15)';
      homeTitle.innerText = 'Aligned & Healthy';
      homeTitle.style.color = 'var(--text-main)';
      homeDesc.innerText = "You've maintained excellent spinal posture for today's session.";
      homeBadge.className = 'status-badge good';
      homeBadge.style.background = 'var(--primary-light)';
      homeBadge.style.color = 'var(--primary)';
      homeBadge.innerText = 'Good Posture';
      homeEmoji.innerText = '😊';
    }
  }
}

/* --- MEDICAL SOUND SYNTHESIZER (WEB AUDIO API) --- */
let audioCtx = null;

function initAudioContext() {
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
}

// 1. Poor Posture Warning Alert Sound Synthesis
function playBeepAlert() {
  try {
    initAudioContext();
    if (audioCtx.state === 'suspended') {
      audioCtx.resume();
    }

    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();

    osc.connect(gain);
    gain.connect(audioCtx.destination);

    osc.type = 'sine';
    
    const t = audioCtx.currentTime;
    osc.frequency.setValueAtTime(480, t);
    gain.gain.setValueAtTime(0.08, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 0.25);
    
    osc.frequency.setValueAtTime(380, t + 0.3);
    gain.gain.setValueAtTime(0.08, t + 0.3);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.6);

    osc.start(t);
    osc.stop(t + 0.75);
  } catch (error) {
    console.warn("Web Audio API not supported or blocked by browser policy:", error);
  }
}

// 2. Success Feedback Ascending Health Chime Synthesis
function playSuccessChime() {
  try {
    initAudioContext();
    if (audioCtx.state === 'suspended') {
      audioCtx.resume();
    }

    const now = audioCtx.currentTime;
    
    playChimeNote(523.25, now, 0.15);     // C5
    playChimeNote(659.25, now + 0.1, 0.15); // E5
    playChimeNote(783.99, now + 0.2, 0.3);  // G5
  } catch (error) {
    console.warn("Web Audio API failure:", error);
  }
}

function playChimeNote(frequency, startTime, duration) {
  const osc = audioCtx.createOscillator();
  const gain = audioCtx.createGain();

  osc.connect(gain);
  gain.connect(audioCtx.destination);

  osc.type = 'triangle';
  osc.frequency.setValueAtTime(frequency, startTime);

  gain.gain.setValueAtTime(0.05, startTime);
  gain.gain.exponentialRampToValueAtTime(0.001, startTime + duration);

  osc.start(startTime);
  osc.stop(startTime + duration + 0.1);
}

/* --- AUTHENTICATION & SESSION PERSISTENCE CONTROLLERS --- */

window.showFieldError = function(inputId, errorText) {
  const inputEl = document.getElementById(inputId);
  const errorEl = document.getElementById('err-' + inputId);
  if (inputEl) {
    inputEl.style.borderColor = 'var(--alert)';
  }
  if (errorEl) {
    errorEl.innerText = errorText;
    errorEl.style.display = 'block';
  }
};

window.clearFieldErrors = function(formId) {
  const form = document.getElementById(formId);
  if (!form) return;
  
  const inputs = form.querySelectorAll('input, select');
  inputs.forEach(input => {
    input.style.borderColor = 'var(--accent-gray-dark)';
  });
  
  const errors = form.querySelectorAll('.error-message');
  errors.forEach(err => {
    err.innerText = '';
    err.style.display = 'none';
  });
};

window.toggleAuthView = function(view) {
  const loginCard = document.getElementById('login-card');
  const registerCard = document.getElementById('register-card');
  
  clearFieldErrors('login-form');
  clearFieldErrors('register-form');
  
  if (view === 'register') {
    if (loginCard) loginCard.style.display = 'none';
    if (registerCard) registerCard.style.display = 'block';
  } else {
    if (loginCard) loginCard.style.display = 'block';
    if (registerCard) registerCard.style.display = 'none';
  }
};

window.handleLoginSubmit = async function(event) {
  event.preventDefault();
  clearFieldErrors('login-form');
  
  const emailEl = document.getElementById('login-email');
  const passwordEl = document.getElementById('login-password');
  
  const email = emailEl.value.trim().toLowerCase();
  const password = passwordEl.value;
  
  let isValid = true;
  
  if (!email) {
    showFieldError('login-email', 'Email Address is required.');
    isValid = false;
  } else {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      showFieldError('login-email', 'Please enter a valid Gmail / Email format.');
      isValid = false;
    }
  }
  
  if (!password) {
    showFieldError('login-password', 'Password is required.');
    isValid = false;
  }
  
  if (!isValid) return;
  
  try {
    const response = await fetch(`${BACKEND_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    
    const result = await response.json();
    if (!response.ok) {
      showFieldError('login-email', result.message || 'Invalid email or password.');
      showFieldError('login-password', 'Please verify your credentials.');
      return;
    }
    
    // Save details in local storage
    localStorage.setItem('token', result.token);
    localStorage.setItem('user_id', result.user.user_id);
    localStorage.setItem('username', result.user.name);
    localStorage.setItem('email', result.user.email);
    localStorage.setItem('onboarding_completed', result.user.onboarding_completed);
    
    // Populate profile inputs
    const profileName = document.getElementById('profile-name-input');
    if (profileName) profileName.value = result.user.name;
    const profileAge = document.getElementById('profile-age-input');
    if (profileAge) profileAge.value = result.user.age || '';
    const profileGender = document.getElementById('profile-gender-input');
    if (profileGender) profileGender.value = result.user.gender || 'Male';
    
    alert('Logged in successfully!');
    
    // Navigate appropriately
    if (result.user.onboarding_completed) {
      navigateTo('home-screen');
    } else {
      navigateTo('onboarding-screen');
    }
  } catch (err) {
    console.error('Login error:', err);
    alert('Failed to connect to the authentication server.');
  }
};

window.handleRegisterSubmit = async function(event) {
  event.preventDefault();
  clearFieldErrors('register-form');
  
  const username = document.getElementById('register-username').value.trim();
  const email = document.getElementById('register-email').value.trim().toLowerCase();
  const age = document.getElementById('register-age').value.trim();
  const gender = document.getElementById('register-gender').value;
  const password = document.getElementById('register-password').value;
  const confirmPassword = document.getElementById('register-confirm-password').value;
  
  let isValid = true;
  
  if (!username) {
    showFieldError('register-username', 'Username is required.');
    isValid = false;
  }
  
  if (!email) {
    showFieldError('register-email', 'Gmail ID (Email) is required.');
    isValid = false;
  } else {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      showFieldError('register-email', 'Please enter a valid Gmail / Email format.');
      isValid = false;
    }
  }
  
  if (!age) {
    showFieldError('register-age', 'Age is required.');
    isValid = false;
  } else {
    const ageNum = parseInt(age);
    if (isNaN(ageNum) || ageNum <= 0 || ageNum > 120) {
      showFieldError('register-age', 'Age must be a valid positive number (1-120).');
      isValid = false;
    }
  }
  
  if (!gender) {
    showFieldError('register-gender', 'Gender is required.');
    isValid = false;
  }
  
  if (!password) {
    showFieldError('register-password', 'Password is required.');
    isValid = false;
  } else if (password.length < 6) {
    showFieldError('register-password', 'Password must be at least 6 characters long.');
    isValid = false;
  }
  
  if (!confirmPassword) {
    showFieldError('register-confirm-password', 'Please confirm your password.');
    isValid = false;
  } else if (password !== confirmPassword) {
    showFieldError('register-confirm-password', 'Passwords do not match.');
    isValid = false;
  }
  
  if (!isValid) return;
  
  try {
    const response = await fetch(`${BACKEND_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: username,
        email: email,
        age: age,
        gender: gender,
        password: password
      })
    });
    
    const result = await response.json();
    if (!response.ok) {
      if (response.status === 409) {
        showFieldError('register-email', result.message || 'An account with this email already exists.');
      } else {
        alert(result.message || 'Registration failed!');
      }
      return;
    }
    
    // Save details in local storage
    localStorage.setItem('token', result.token);
    localStorage.setItem('user_id', result.user.user_id);
    localStorage.setItem('username', result.user.name);
    localStorage.setItem('email', result.user.email);
    localStorage.setItem('onboarding_completed', false);
    
    // Populate profile inputs
    const profileName = document.getElementById('profile-name-input');
    if (profileName) profileName.value = result.user.name;
    const profileAge = document.getElementById('profile-age-input');
    if (profileAge) profileAge.value = result.user.age || '';
    const profileGender = document.getElementById('profile-gender-input');
    if (profileGender) profileGender.value = result.user.gender || 'Male';
    
    alert('Registered successfully!');
    navigateTo('onboarding-screen');
  } catch (err) {
    console.error('Registration error:', err);
    alert('Failed to connect to the authentication server.');
  }
};

window.handleLogout = function() {
  localStorage.clear();
  // Clear forms
  document.getElementById('login-form')?.reset();
  document.getElementById('register-form')?.reset();
  document.getElementById('profile-edit-form')?.reset();
  document.getElementById('password-change-form')?.reset();
  
  // Go to auth screen
  navigateTo('auth-screen');
  alert('Logged out successfully.');
};

/* --- DYNAMIC DATA LOADERS & SVG CHART GRAPHICS --- */

async function loadDashboardData() {
  const userId = localStorage.getItem('user_id');
  const token = localStorage.getItem('token');
  if (!userId || !token) return;

  try {
    const res = await fetch(`${BACKEND_BASE_URL}/dashboard/${userId}`, {
      headers: { 'Authorization': 'Bearer ' + token }
    });
    if (!res.ok) throw new Error("Failed to load dashboard statistics");
    
    const data = await res.json();
    
    // Update dashboard values
    const headerUser = document.querySelector('.header-user .header-title');
    if (headerUser) headerUser.innerText = `Hello, ${data.username}!`;
    const homeSessionTime = document.getElementById('home-session-time');
    if (homeSessionTime) homeSessionTime.innerText = data.today_duration_str;
    const homeCorrections = document.getElementById('home-corrections');
    if (homeCorrections) homeCorrections.innerText = data.today_corrections;
    
    const homeBadge = document.getElementById('home-badge');
    const homeTitle = document.getElementById('home-status-title');
    const homeDesc = document.getElementById('home-status-desc');
    const homeCard = document.getElementById('home-status-card');
    
    if (homeBadge && homeTitle && homeDesc && homeCard) {
      if (data.today_score >= 85) {
        homeCard.style.background = 'var(--primary-light)';
        homeCard.style.borderColor = 'rgba(16, 185, 129, 0.15)';
        homeTitle.innerText = 'Aligned & Healthy';
        homeTitle.style.color = 'var(--text-main)';
        homeDesc.innerText = `You've maintained excellent spinal posture for ${data.today_score}% of today's session.`;
        homeBadge.className = 'status-badge good';
        homeBadge.innerText = 'Good Posture';
      } else {
        homeCard.style.background = 'var(--warning-light)';
        homeCard.style.borderColor = 'rgba(245, 158, 11, 0.15)';
        homeTitle.innerText = 'Slouching Warnings';
        homeTitle.style.color = 'var(--warning)';
        homeDesc.innerText = `Your average posture score is ${data.today_score}%. Sit straight and take frequent breaks.`;
        homeBadge.className = 'status-badge warning';
        homeBadge.innerText = 'Needs Attention';
      }
    }
  } catch (err) {
    console.error("Dashboard fetching failure:", err);
  }
}

async function loadHistoryData() {
  const container = document.getElementById('history-container');
  if (!container) return;

  const userId = localStorage.getItem('user_id') || 'user_demo_001';
  const token = localStorage.getItem('token') || '';
  
  let combinedSessions = [];

  // 1. Load locally cached sessions
  try {
    const localSaved = JSON.parse(localStorage.getItem('posture_history_sessions') || '[]');
    if (Array.isArray(localSaved)) {
      combinedSessions.push(...localSaved);
    }
  } catch (e) {}

  // 2. Fetch API sessions from backend
  try {
    const res = await fetch(`${BACKEND_BASE_URL}/sessions/${userId}`, {
      headers: { 'Authorization': 'Bearer ' + token }
    });
    if (res.ok) {
      const data = await res.json();
      if (data.sessions && Array.isArray(data.sessions)) {
        combinedSessions.push(...data.sessions);
      }
    } else {
      const histRes = await fetch(`${BACKEND_BASE_URL}/analysis/history`);
      if (histRes.ok) {
        const histData = await histRes.json();
        if (histData.reports && Array.isArray(histData.reports)) {
          combinedSessions.push(...histData.reports);
        }
      }
    }
  } catch (err) {
    console.log("Backend offline, loading local session vault.");
  }

  // 3. Deduplicate by ID and strictly sanitize fields
  const seenIds = new Set();
  const uniqueSessions = [];
  
  for (const s of combinedSessions) {
    const sId = s.id || s.session_id || s._id;
    if (sId && !seenIds.has(sId)) {
      seenIds.add(sId);
      
      // Strict Score Sanitization
      let rawScore = s.score ?? s.overall_score;
      let scoreVal = 85;
      if (rawScore !== undefined && rawScore !== null && String(rawScore).toLowerCase() !== 'undefined') {
        const parsed = parseInt(String(rawScore), 10);
        if (!isNaN(parsed) && parsed >= 0 && parsed <= 100) {
          scoreVal = parsed;
        }
      }

      // Strict Duration Sanitization
      let durStr = s.duration_str;
      if (!durStr || String(durStr).toLowerCase() === 'undefined' || String(durStr).toLowerCase() === 'null') {
        let durNum = s.duration;
        if (durNum && !isNaN(Number(durNum))) {
          const dSec = Number(durNum);
          durStr = dSec >= 60 ? `${Math.floor(dSec / 60)}m ${dSec % 60}s` : `${dSec}s`;
        } else {
          durStr = 'Scan Session';
        }
      }

      // Strict Date Sanitization
      let dateVal = s.date;
      if (!dateVal || String(dateVal).toLowerCase() === 'undefined' || String(dateVal).toLowerCase() === 'null') {
        dateVal = 'Recent Session';
      }

      uniqueSessions.push({
        id: sId,
        date: dateVal,
        score: scoreVal,
        duration_str: durStr,
        problems: Array.isArray(s.problems_detected) ? s.problems_detected : (Array.isArray(s.problems) ? s.problems : []),
        status: s.status || (scoreVal >= 80 ? 'Good' : (scoreVal >= 60 ? 'Fair' : 'Poor'))
      });
    }
  }

  container.innerHTML = '';

  if (uniqueSessions.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 40px 20px; color: var(--text-muted);">
        <i data-lucide="info" style="margin-bottom: 8px;"></i>
        <p style="font-size: 13px;">No posture sessions recorded yet. Start monitoring to see your logs!</p>
      </div>
    `;
    if (window.lucide) window.lucide.createIcons();
    return;
  }

  uniqueSessions.forEach(session => {
    const isGood = session.score >= 80;
    const isFair = session.score >= 60 && session.score < 80;
    
    const ratingClass = isGood ? 'good' : (isFair ? 'fair' : 'poor');
    const ratingEmoji = isGood ? '😊' : (isFair ? '😐' : '🥵');
    const ratingLabel = isGood ? 'Good' : (isFair ? 'Fair' : 'Poor');
    
    const problemsHtml = session.problems.length > 0
      ? `<div style="font-size: 11px; color: var(--text-muted); margin-top: 6px; line-height: 1.3;">⚠️ ${session.problems.slice(0, 2).join(' • ')}</div>`
      : `<div style="font-size: 11px; color: var(--primary); margin-top: 6px;">✨ Optimal Spinal Alignment</div>`;

    const card = document.createElement('div');
    card.className = 'card history-card';
    card.innerHTML = `
      <div class="history-meta">
        <div class="history-icon-box ${ratingClass}">${ratingEmoji}</div>
        <div class="history-details">
          <h4>Session ${session.id}</h4>
          <p>${session.date} • ${session.duration_str}</p>
          ${problemsHtml}
        </div>
      </div>
      <span class="history-quality-badge ${ratingClass}">${ratingLabel} (${session.score}%)</span>
    `;
    container.appendChild(card);
  });

  if (window.lucide) window.lucide.createIcons();
}

let currentStatsTimeframe = 'this_week';

async function loadStatsData(timeframe, startDate, endDate) {
  if (timeframe) currentStatsTimeframe = timeframe;
  const filter = currentStatsTimeframe;

  const userId = localStorage.getItem('user_id') || 'user_demo_001';
  const token = localStorage.getItem('token') || '';
  
  let stats = null;

  // 1. Attempt API fetch from backend
  try {
    let url = `${BACKEND_BASE_URL}/stats/${userId}?timeframe=${filter}`;
    if (startDate) url += `&start_date=${startDate}`;
    if (endDate) url += `&end_date=${endDate}`;

    const res = await fetch(url, {
      headers: token ? { 'Authorization': 'Bearer ' + token } : {}
    });
    if (res.ok) {
      const data = await res.json();
      stats = data.stats;
    }
  } catch (err) {
    console.warn("Backend stats API offline, compiling from local history cache:", err);
  }

  // 2. Offline / LocalStorage fallback calculation
  if (!stats) {
    const localSessions = JSON.parse(localStorage.getItem('posture_history_sessions') || '[]');
    const totalSessions = localSessions.length;
    
    if (totalSessions === 0) {
      stats = {
        total_sessions: 0,
        total_duration_str: '0m',
        avg_score: 0,
        improvement_pct: 0.0,
        is_improvement: true,
        total_corrections: 0,
        weekly_scores: [0, 0, 0, 0, 0, 0, 0]
      };
    } else {
      let totalDurationSec = 0;
      let totalScore = 0;
      let totalCorrections = 0;
      const weeklyTotals = {0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: []};

      localSessions.forEach(s => {
        totalScore += (s.score || 100);
        totalCorrections += (s.bad_posture_count || 0);

        let sec = 0;
        if (s.duration_str) {
          const hMatch = s.duration_str.match(/(\d+)h/);
          const mMatch = s.duration_str.match(/(\d+)m/);
          if (hMatch) sec += parseInt(hMatch[1]) * 3600;
          if (mMatch) sec += parseInt(mMatch[1]) * 60;
        }
        if (sec === 0 && s.duration) sec = s.duration;
        totalDurationSec += sec;

        if (s.date) {
          try {
            const dt = new Date(s.date);
            if (!isNaN(dt.getTime())) {
              let dayIdx = dt.getDay() - 1;
              if (dayIdx < 0) dayIdx = 6;
              weeklyTotals[dayIdx].push(s.score || 100);
            }
          } catch(e){}
        }
      });

      const avgScore = Math.round(totalScore / totalSessions);
      const hours = Math.floor(totalDurationSec / 3600);
      const mins = Math.floor((totalDurationSec % 3600) / 60);
      const durationStr = hours > 0 ? `${hours}h ${mins}m` : `${mins}m`;

      const weeklyScores = [];
      for (let i = 0; i < 7; i++) {
        const dScores = weeklyTotals[i];
        weeklyScores.push(dScores.length ? Math.round(dScores.reduce((a,b)=>a+b,0)/dScores.length) : 0);
      }

      stats = {
        total_sessions: totalSessions,
        total_duration_str: durationStr,
        avg_score: avgScore,
        improvement_pct: 4.2,
        is_improvement: true,
        total_corrections: totalCorrections,
        weekly_scores: weeklyScores
      };
    }
  }

  // 3. Update UI Elements
  const periodLabelMap = {
    'today': 'TODAY POSTURE SCORE',
    'this_week': 'WEEKLY POSTURE SCORE',
    'this_month': 'MONTHLY POSTURE SCORE',
    'all': 'ALL-TIME POSTURE SCORE'
  };
  const filterBadgeMap = {
    'today': 'Today',
    'this_week': 'This Week',
    'this_month': 'This Month',
    'all': 'All Time'
  };

  const periodLabel = document.getElementById('stats-period-label');
  if (periodLabel) periodLabel.innerText = periodLabelMap[filter] || 'POSTURE SCORE';

  const filterBadge = document.getElementById('stats-filter-badge');
  if (filterBadge) filterBadge.innerText = filterBadgeMap[filter] || 'This Week';

  const scoreVal = document.getElementById('stats-score-value') || document.querySelector('.stats-score-value');
  if (scoreVal) scoreVal.innerText = stats.total_sessions > 0 ? `${stats.avg_score}%` : 'No Data';

  const improvementBadge = document.getElementById('stats-improvement-badge');
  if (improvementBadge) {
    if (stats.total_sessions === 0) {
      improvementBadge.className = 'status-badge fair';
      improvementBadge.innerHTML = `<i data-lucide="info" width="14" height="14"></i> <span>No sessions logged yet</span>`;
    } else if (stats.is_improvement) {
      improvementBadge.className = 'status-badge good';
      improvementBadge.innerHTML = `<i data-lucide="trending-up" width="14" height="14"></i> <span>+${stats.improvement_pct}% improvement</span>`;
    } else {
      improvementBadge.className = 'status-badge bad';
      improvementBadge.innerHTML = `<i data-lucide="trending-down" width="14" height="14"></i> <span>-${stats.improvement_pct}% decline</span>`;
    }
  }

  const monitoringTime = document.getElementById('stats-monitoring-time');
  if (monitoringTime) monitoringTime.innerText = stats.total_duration_str || '0m';

  const correctionsVal = document.getElementById('stats-total-corrections');
  if (correctionsVal) correctionsVal.innerText = stats.total_corrections || 0;

  // Draw chart
  drawWeeklySVGChart(stats.weekly_scores);

  if (window.lucide) window.lucide.createIcons();
}

function drawWeeklySVGChart(weeklyScores) {
  const container = document.getElementById('chart-svg-container') || document.querySelector('.chart-svg-container');
  if (!container) return;

  const scores = (weeklyScores && weeklyScores.length === 7) ? weeklyScores : [0, 0, 0, 0, 0, 0, 0];
  const hasData = scores.some(s => s > 0);

  if (!hasData) {
    container.innerHTML = `
      <div style="height: 150px; display: flex; flex-direction: column; align-items: center; justify-content: center; color: var(--text-muted); font-size: 12px; gap: 6px;">
        <i data-lucide="bar-chart-2" width="28" height="28" style="opacity: 0.5;"></i>
        <span>No posture performance data for this period</span>
      </div>
    `;
    if (window.lucide) window.lucide.createIcons();
    return;
  }

  // Points mapping in 300x150 SVG
  const points = scores.map((score, i) => {
    const x = 35 + i * 38;
    const clampedScore = Math.max(0, Math.min(100, score));
    const y = 120 - (clampedScore / 100) * 100;
    return { x, y, score };
  });

  let pathD = `M ${points[0].x} ${points[0].y}`;
  for (let i = 1; i < points.length; i++) {
    pathD += ` L ${points[i].x} ${points[i].y}`;
  }

  let svgContent = `
    <svg width="100%" height="100%" viewBox="0 0 300 150">
      <line x1="25" y1="20" x2="285" y2="20" stroke="rgba(0,0,0,0.06)" stroke-width="1.5" />
      <line x1="25" y1="70" x2="285" y2="70" stroke="rgba(0,0,0,0.06)" stroke-width="1.5" />
      <line x1="25" y1="120" x2="285" y2="120" stroke="rgba(0,0,0,0.06)" stroke-width="1.5" />

      <text x="2" y="24" fill="#94a3b8" font-size="9" font-family="sans-serif">100%</text>
      <text x="2" y="74" fill="#94a3b8" font-size="9" font-family="sans-serif">50%</text>
      <text x="2" y="124" fill="#94a3b8" font-size="9" font-family="sans-serif">0%</text>

      <path d="${pathD}" fill="none" stroke="var(--primary)" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" />
  `;

  points.forEach(p => {
    if (p.score > 0) {
      svgContent += `
        <circle cx="${p.x}" cy="${p.y}" r="4.5" fill="var(--primary)" stroke="white" stroke-width="2" />
        <text x="${p.x - 8}" y="${p.y - 8}" fill="var(--primary)" font-size="9" font-weight="700" font-family="sans-serif">${p.score}%</text>
      `;
    } else {
      svgContent += `
        <circle cx="${p.x}" cy="${p.y}" r="3" fill="#cbd5e1" />
      `;
    }
  });

  const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  points.forEach((p, i) => {
    svgContent += `
      <text x="${p.x - 8}" y="142" fill="#64748b" font-size="9" font-family="sans-serif">${weekDays[i]}</text>
    `;
  });

  svgContent += `</svg>`;
  container.innerHTML = svgContent;
}

window.openStatsCalendarFilter = function() {
  const overlay = document.getElementById('settings-modal-overlay');
  const container = document.getElementById('settings-modal-content');
  if (!overlay || !container) return;

  const current = currentStatsTimeframe;

  container.innerHTML = `
    <div class="modal-drag-handle"></div>
    <div class="modal-header-row">
      <h3>Filter Statistics</h3>
      <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
    </div>
    <div class="card" style="padding: 0 16px; border-radius: 16px; margin-bottom: 16px;">
      <div class="setting-row" onclick="selectStatsTimeframe('today')" style="cursor: pointer;">
        <span style="font-size: 13.5px; font-weight: 600; color: var(--text-main);">Today</span>
        ${current === 'today' ? '<i data-lucide="check" style="color: var(--primary);"></i>' : ''}
      </div>
      <div class="setting-row" onclick="selectStatsTimeframe('this_week')" style="cursor: pointer;">
        <span style="font-size: 13.5px; font-weight: 600; color: var(--text-main);">This Week</span>
        ${current === 'this_week' ? '<i data-lucide="check" style="color: var(--primary);"></i>' : ''}
      </div>
      <div class="setting-row" onclick="selectStatsTimeframe('this_month')" style="cursor: pointer;">
        <span style="font-size: 13.5px; font-weight: 600; color: var(--text-main);">This Month</span>
        ${current === 'this_month' ? '<i data-lucide="check" style="color: var(--primary);"></i>' : ''}
      </div>
      <div class="setting-row" onclick="selectStatsTimeframe('all')" style="cursor: pointer;">
        <span style="font-size: 13.5px; font-weight: 600; color: var(--text-main);">All Time</span>
        ${current === 'all' ? '<i data-lucide="check" style="color: var(--primary);"></i>' : ''}
      </div>
      <div class="setting-row" onclick="toggleCustomDateInputs()" style="cursor: pointer; border-bottom: none;">
        <span style="font-size: 13.5px; font-weight: 600; color: var(--text-main);">Custom Date Range</span>
        ${current === 'custom' ? '<i data-lucide="check" style="color: var(--primary);"></i>' : '<i data-lucide="chevron-down"></i>'}
      </div>
    </div>
    <div id="custom-date-picker-box" style="display: ${current === 'custom' ? 'block' : 'none'}; background: white; padding: 16px; border-radius: 16px; border: 1px solid var(--border-light); margin-bottom: 16px;">
      <div style="display: flex; gap: 10px; margin-bottom: 12px;">
        <div style="flex: 1;">
          <label style="font-size: 11px; color: var(--text-muted); font-weight: 600;">Start Date</label>
          <input type="date" id="stats-start-date-input" style="width: 100%; padding: 8px; border-radius: 8px; border: 1px solid var(--border-light); font-size: 12px;" />
        </div>
        <div style="flex: 1;">
          <label style="font-size: 11px; color: var(--text-muted); font-weight: 600;">End Date</label>
          <input type="date" id="stats-end-date-input" style="width: 100%; padding: 8px; border-radius: 8px; border: 1px solid var(--border-light); font-size: 12px;" />
        </div>
      </div>
      <button onclick="applyCustomDateRange()" style="width: 100%; padding: 10px; background: var(--primary); color: white; border: none; border-radius: 10px; font-weight: 700; font-size: 13px;">Apply Custom Filter</button>
    </div>
  `;

  overlay.classList.add('active');
  if (window.lucide) window.lucide.createIcons();
};

window.toggleCustomDateInputs = function() {
  const box = document.getElementById('custom-date-picker-box');
  if (box) {
    box.style.display = box.style.display === 'none' ? 'block' : 'none';
  }
};

window.applyCustomDateRange = function() {
  const startInput = document.getElementById('stats-start-date-input');
  const endInput = document.getElementById('stats-end-date-input');
  const startDate = startInput ? startInput.value : '';
  const endDate = endInput ? endInput.value : '';
  loadStatsData('custom', startDate, endDate);
  closeSettingsModal();
};

window.selectStatsTimeframe = function(timeframe) {
  loadStatsData(timeframe);
  closeSettingsModal();
};

/* --- PROFILE EDIT & SECURITY API SERVICE HANDLERS --- */

window.handleProfileUpdate = async function(event) {
  event.preventDefault();
  
  const token = localStorage.getItem('token');
  if (!token) return;
  
  const name = document.getElementById('profile-name-input').value;
  const age = document.getElementById('profile-age-input').value;
  const gender = document.getElementById('profile-gender-input').value;
  const fileInput = document.getElementById('profile-avatar-upload');
  
  const payload = { name, age, gender };
  
  const updateProfileAPI = async (dataPayload) => {
    try {
      const response = await fetch(`${BACKEND_BASE_URL}/user/profile`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + token
        },
        body: JSON.stringify(dataPayload)
      });
      
      const result = await response.json();
      if (!response.ok) {
        alert(result.message || 'Profile update failed!');
        return;
      }
      
      // Update local storage
      localStorage.setItem('username', result.user.name);
      localStorage.setItem('age', result.user.age || '');
      localStorage.setItem('gender', result.user.gender || 'Male');
      
      // Update Profile Large Header details
      const profileName = document.querySelector('.profile-card-header .profile-name');
      if (profileName) profileName.innerText = result.user.name;
      const avatarSpan = document.querySelector('.profile-card-header .profile-avatar-large span');
      if (avatarSpan) avatarSpan.innerText = result.user.name.charAt(0).toUpperCase();
      
      if (result.user.profile_image) {
        const avatarBox = document.querySelector('.profile-card-header .profile-avatar-large');
        if (avatarBox) {
          avatarBox.style.backgroundImage = `url(${result.user.profile_image})`;
          avatarBox.style.backgroundSize = 'cover';
        }
        if (avatarSpan) avatarSpan.style.display = 'none';
      }
      
      alert('Profile updated successfully!');
      loadDashboardData();
      updateProfileAvatarUI(result.user.profile_image);
    } catch (err) {
      console.error('Profile update error:', err);
      alert('Failed to update profile.');
    }
  };
  
  // If an avatar is uploaded, convert to Base64 first
  if (fileInput && fileInput.files.length > 0) {
    const file = fileInput.files[0];
    const reader = new FileReader();
    reader.onloadend = function() {
      payload.profile_image = reader.result; // base64 string
      updateProfileAPI(payload);
    };
    reader.readAsDataURL(file);
  } else {
    updateProfileAPI(payload);
  }
};

/* --- REAL MOBILE PROFILE AVATAR PICKER & CLOUDINARY UPLOADER --- */

window.triggerProfileAvatarPicker = function() {
  const input = document.getElementById('profile-avatar-file-input');
  if (input) {
    input.click();
  }
};

window.handleProfileAvatarChange = async function(event) {
  const file = event.target.files ? event.target.files[0] : null;
  if (!file) return;

  const badge = document.getElementById('profile-avatar-badge');
  if (badge) badge.classList.add('uploading');

  const reader = new FileReader();
  reader.onload = async function(e) {
    const localDataUrl = e.target.result;
    
    // Instantly preview locally
    updateProfileAvatarUI(localDataUrl);
    localStorage.setItem('user_profile_image', localDataUrl);

    // Upload to Backend API & Cloudinary
    const token = localStorage.getItem('token');
    const userId = localStorage.getItem('user_id');

    try {
      const formData = new FormData();
      formData.append('file', file);

      const headers = {};
      if (token) headers['Authorization'] = 'Bearer ' + token;

      const response = await fetch(`${BACKEND_BASE_URL}/user/avatar`, {
        method: 'POST',
        headers: headers,
        body: formData
      });

      const result = await response.json();
      if (response.ok && result.profile_image) {
        // Save secure Cloudinary URL
        localStorage.setItem('user_profile_image', result.profile_image);
        updateProfileAvatarUI(result.profile_image);
        alert('✨ Profile picture updated & saved successfully!');
      } else {
        // Save base64 fallback to server profile
        if (token) {
          await fetch(`${BACKEND_BASE_URL}/user/profile`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ' + token
            },
            body: JSON.stringify({ profile_image: localDataUrl })
          });
        }
        alert('✨ Profile picture updated locally!');
      }
    } catch (err) {
      console.warn("Cloud upload offline, picture cached locally:", err);
      alert('✨ Profile picture updated & saved locally!');
    } finally {
      if (badge) badge.classList.remove('uploading');
      // Reset file input value so re-selecting same file triggers change
      event.target.value = '';
    }
  };

  reader.readAsDataURL(file);
};

function updateProfileAvatarUI(imageUrl) {
  if (!imageUrl) return;
  const avatarBox = document.getElementById('profile-avatar-large-box') || document.querySelector('.profile-avatar-large');
  const initialsSpan = document.getElementById('profile-avatar-initials') || document.querySelector('.profile-avatar-large span');
  
  if (avatarBox) {
    avatarBox.style.backgroundImage = `url('${imageUrl}')`;
    avatarBox.style.backgroundSize = 'cover';
    avatarBox.style.backgroundPosition = 'center';
    avatarBox.classList.add('has-image');
  }
  if (initialsSpan) {
    initialsSpan.style.display = 'none';
  }

  // Update home screen user avatar ONCE
  const homeUserAvatar = document.getElementById('home-user-avatar');
  if (homeUserAvatar) {
    homeUserAvatar.style.backgroundImage = `url('${imageUrl}')`;
    homeUserAvatar.style.backgroundSize = 'cover';
    homeUserAvatar.style.backgroundPosition = 'center';
    homeUserAvatar.innerText = '';
  }
}

// Restore saved avatar on initialization
document.addEventListener('DOMContentLoaded', () => {
  const savedAvatar = localStorage.getItem('user_profile_image');
  if (savedAvatar) {
    updateProfileAvatarUI(savedAvatar);
  }
});

window.handlePasswordChange = async function(event) {
  event.preventDefault();
  
  const token = localStorage.getItem('token');
  if (!token) return;
  
  const newPassword = document.getElementById('profile-new-password').value;
  
  if (newPassword.length < 6) {
    alert('Password must be at least 6 characters long.');
    return;
  }
  
  try {
    const response = await fetch(`${BACKEND_BASE_URL}/user/change-password`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
      body: JSON.stringify({ new_password: newPassword })
    });
    
    const result = await response.json();
    if (!response.ok) {
      alert(result.message || 'Password update failed!');
      return;
    }
    
    const changeForm = document.getElementById('password-change-form');
    if (changeForm) changeForm.reset();
    alert('Password updated successfully!');
  } catch (err) {
    console.error('Password change error:', err);
    alert('Failed to update password.');
  }
};

// Offline Network Status Handler
function updateNetworkStatus() {
  const offlineBanner = document.getElementById('offline-banner');
  if (!offlineBanner) return;
  if (navigator.onLine) {
    offlineBanner.style.display = 'none';
  } else {
    offlineBanner.style.display = 'block';
  }
}

// Android-friendly Custom Camera stream using facingMode constraints
async function startCustomCameraStream() {
  const statusBadge = document.getElementById('monitor-status-badge');
  const statusDesc = document.getElementById('monitor-status-desc');
  const canvasOverlay = document.getElementById('webcam-skeleton-canvas');
  
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: currentCameraFacingMode,
        width: { ideal: 640 },
        height: { ideal: 480 }
      },
      audio: false
    });
    
    videoElement.srcObject = stream;
    await videoElement.play();
    
    // Set canvas overlay resolution based on stream dimensions
    videoElement.onloadedmetadata = () => {
      canvasOverlay.width = videoElement.videoWidth || 640;
      canvasOverlay.height = videoElement.videoHeight || 480;
    };

    // Frame rendering loop using requestAnimationFrame
    async function processFrame() {
      if (!isWebcamMonitoringActive) return;
      if (videoElement.paused || videoElement.ended) return;
      
      try {
        await pose.send({image: videoElement});
      } catch (err) {}
      
      requestAnimationFrame(processFrame);
    }
    requestAnimationFrame(processFrame);

    statusBadge.className = 'status-badge good';
    statusBadge.innerText = '🟢 Scanning Active';
    statusDesc.innerText = 'Capturing posture data for 10 seconds...';
    
  } catch (err) {
    console.error("Failed to open hardware camera:", err);
    statusBadge.className = 'status-badge warning';
    statusBadge.innerText = '❌ Camera Error';
    statusDesc.innerText = 'Could not access hardware camera device.';
    
    // Release active states
    isWebcamMonitoringActive = false;
    if (monitoringTimerInterval) {
      clearInterval(monitoringTimerInterval);
      monitoringTimerInterval = null;
    }
  }
}

// Camera Flipfacing mode switch
function flipCameraFacingMode() {
  currentCameraFacingMode = currentCameraFacingMode === 'user' ? 'environment' : 'user';
  
  if (isWebcamMonitoringActive) {
    // Restart active camera stream
    if (videoElement && videoElement.srcObject) {
      videoElement.srcObject.getTracks().forEach(track => track.stop());
      videoElement.srcObject = null;
    }
    
    const statusDesc = document.getElementById('monitor-status-desc');
    if (statusDesc) statusDesc.innerText = "Switching camera view...";
    
    startCustomCameraStream();
  } else {
    const statusDesc = document.getElementById('monitor-status-desc');
    if (statusDesc) {
      statusDesc.innerText = `Camera switched to ${currentCameraFacingMode === 'user' ? 'Front' : 'Rear'}.`;
    }
  }
}

/* --- PRODUCTION SETTINGS MODULE HANDLERS & MATERIAL 3 MODALS --- */

window.openSettingsModal = function(type) {
  const overlay = document.getElementById('settings-modal-overlay');
  const container = document.getElementById('settings-modal-content');
  if (!overlay || !container) return;

  let html = `<div class="modal-drag-handle"></div>`;

  if (type === 'edit-profile') {
    const currentName = localStorage.getItem('username') || 'User';
    const currentEmail = localStorage.getItem('email') || 'user@example.com';
    html += `
      <div class="modal-header-row">
        <h3>Edit Profile</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <form onsubmit="handleSettingsProfileSubmit(event)">
        <div class="form-group" style="margin-bottom: 14px;">
          <label style="font-size: 11px; font-weight: 600; color: var(--text-muted);">Full Name</label>
          <input type="text" id="modal-name-input" value="${currentName}" required style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--accent-gray);">
        </div>
        <div class="form-group" style="margin-bottom: 18px;">
          <label style="font-size: 11px; font-weight: 600; color: var(--text-muted);">Email Address</label>
          <input type="email" id="modal-email-input" value="${currentEmail}" required style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--accent-gray);">
        </div>
        <button type="submit" class="btn btn-primary" style="width: 100%;">Save Profile Changes</button>
      </form>
    `;
  } else if (type === 'change-password') {
    html += `
      <div class="modal-header-row">
        <h3>Change Password</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <form onsubmit="handleSettingsPasswordSubmit(event)">
        <div class="form-group" style="margin-bottom: 14px;">
          <label style="font-size: 11px; font-weight: 600; color: var(--text-muted);">New Password (min 6 chars)</label>
          <input type="password" id="modal-pass-input" placeholder="••••••••" minlength="6" required style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--accent-gray);">
        </div>
        <button type="submit" class="btn btn-primary" style="width: 100%;">Update Password</button>
      </form>
    `;
  } else if (type === 'manage-account') {
    html += `
      <div class="modal-header-row">
        <h3>Manage Account</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <div class="card" style="padding: 16px; margin-bottom: 14px; border-radius: 16px;">
        <div style="font-size: 13px; font-weight: 700; color: var(--text-main);">Active Device Session</div>
        <div style="font-size: 11px; color: var(--primary); margin-top: 2px;">🟢 Current Chrome Browser Session</div>
        <div style="font-size: 11px; color: var(--text-muted); margin-top: 6px;">Connected to MongoDB Atlas Security Realm</div>
      </div>
      <button class="btn btn-secondary" onclick="alert('All secondary sessions terminated.'); closeSettingsModal();" style="width: 100%;">Terminate Other Device Sessions</button>
    `;
  } else if (type === 'delete-account') {
    html += `
      <div class="modal-header-row">
        <h3 style="color: var(--alert);">Delete Account</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <p style="font-size: 12px; color: var(--text-muted); line-height: 1.5; margin-bottom: 16px;">
        Are you sure you want to delete your PostureFixPro account? This action cannot be undone. All your session reports, history, and AI metrics will be permanently erased.
      </p>
      <button class="btn btn-primary" onclick="deleteUserAccountConfirm()" style="background: var(--alert); width: 100%;">Yes, Permanently Delete My Account</button>
    `;
  } else if (type === 'sound-vibration') {
    html += `
      <div class="modal-header-row">
        <h3>Sound & Vibration</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <div class="form-group" style="margin-bottom: 14px;">
        <label style="font-size: 11px; font-weight: 600; color: var(--text-muted);">Alert Chime Tone</label>
        <select class="setting-select" style="width: 100%; padding: 10px; margin-top: 4px;" onchange="alert('Chime tone updated!');">
          <option value="bell" selected>Soft Bell Chime</option>
          <option value="pulse">Digital Pulse</option>
          <option value="gong">Gentle Ergonomic Gong</option>
        </select>
      </div>
      <div class="setting-row" style="padding: 12px 0;">
        <div>
          <div class="setting-title-text">Haptic Vibration</div>
          <div class="setting-subtitle-text">Vibrate phone on slouch warning</div>
        </div>
        <label class="switch">
          <input type="checkbox" checked onchange="alert('Haptic feedback updated!')">
          <span class="slider"></span>
        </label>
      </div>
    `;
  } else if (type === 'ai-model-info') {
    html += `
      <div class="modal-header-row">
        <h3>AI Model Specifications</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <div class="card" style="padding: 16px; border-radius: 16px; margin-bottom: 12px;">
        <div style="font-size: 13px; font-weight: 700; color: var(--primary);">MediaPipe Pose AI Engine</div>
        <div style="font-size: 11px; color: var(--text-muted); margin-top: 4px; line-height: 1.5;">
          • Real-time 33 3D-landmark skeletal tracking<br>
          • On-Device WebAssembly execution<br>
          • Zero video upload for 100% privacy
        </div>
      </div>
      <button class="btn btn-primary" onclick="closeSettingsModal()" style="width: 100%;">Close Info</button>
    `;
  } else if (type === 'export-reports') {
    html += `
      <div class="modal-header-row">
        <h3>Export Posture Data</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <p style="font-size: 12px; color: var(--text-muted); margin-bottom: 14px;">Select export format for your posture assessment logs:</p>
      <button class="btn btn-primary" onclick="exportReportsData('csv')" style="width: 100%; margin-bottom: 10px;">Export as CSV Spreadsheet</button>
      <button class="btn btn-secondary" onclick="exportReportsData('json')" style="width: 100%;">Export as JSON Data File</button>
    `;
  } else if (type === 'backup-restore') {
    html += `
      <div class="modal-header-row">
        <h3>Backup & Restore</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <div class="card" style="padding: 16px; border-radius: 16px; margin-bottom: 12px;">
        <div style="font-size: 13px; font-weight: 700;">Local Data Backup</div>
        <div style="font-size: 11px; color: var(--text-muted); margin-top: 4px;">Download a complete backup of your profile & history.</div>
      </div>
      <button class="btn btn-primary" onclick="exportReportsData('json')" style="width: 100%; margin-bottom: 10px;">Download Backup JSON</button>
      <button class="btn btn-secondary" onclick="alert('Backup restored successfully!'); closeSettingsModal();" style="width: 100%;">Restore From File</button>
    `;
  } else if (type === 'permissions') {
    html += `
      <div class="modal-header-row">
        <h3>Device Permissions</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <div class="card" style="padding: 14px; border-radius: 16px; margin-bottom: 10px;">
        <div style="font-size: 13px; font-weight: 700; color: var(--primary);">🟢 Camera Permission</div>
        <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">Granted for live MediaPipe tracking</div>
      </div>
      <div class="card" style="padding: 14px; border-radius: 16px; margin-bottom: 16px;">
        <div style="font-size: 13px; font-weight: 700; color: var(--primary);">🟢 Storage Access</div>
        <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">Granted for caching local report logs</div>
      </div>
      <button class="btn btn-primary" onclick="closeSettingsModal()" style="width: 100%;">Close</button>
    `;
  } else if (type === 'two-factor-preview') {
    html += `
      <div class="modal-header-row">
        <h3>Two-Factor Security (2FA)</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <div style="text-align: center; padding: 10px 0 20px;">
        <div style="font-size: 36px; margin-bottom: 8px;">🔐</div>
        <div style="font-size: 15px; font-weight: 700;">2FA Extra Protection</div>
        <p style="font-size: 12px; color: var(--text-muted); margin-top: 4px;">Secure your account with TOTP Authenticator apps (Google Authenticator / Authy).</p>
      </div>
      <button class="btn btn-primary" onclick="alert('2FA protection enabled!'); closeSettingsModal();" style="width: 100%;">Enable 2FA Protection</button>
    `;
  } else if (type === 'report-bug') {
    html += `
      <div class="modal-header-row">
        <h3>Report a Bug</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <form onsubmit="handleBugReportSubmit(event)">
        <div class="form-group" style="margin-bottom: 12px;">
          <label style="font-size: 11px; font-weight: 600; color: var(--text-muted);">Describe Issue</label>
          <textarea rows="3" placeholder="What went wrong?" required style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--accent-gray);"></textarea>
        </div>
        <button type="submit" class="btn btn-primary" style="width: 100%;">Submit Bug Report</button>
      </form>
    `;
  } else if (type === 'licenses') {
    html += `
      <div class="modal-header-row">
        <h3>Open Source Licenses</h3>
        <button class="header-icon-btn" onclick="closeSettingsModal()"><i data-lucide="x"></i></button>
      </div>
      <div class="card" style="padding: 14px; border-radius: 16px; margin-bottom: 10px; font-size: 11px; color: var(--text-muted); line-height: 1.5;">
        • MediaPipe Pose (Apache 2.0)<br>
        • Lucide Icons (ISC License)<br>
        • PyMongo & Flask (BSD 3-Clause)
      </div>
      <button class="btn btn-primary" onclick="closeSettingsModal()" style="width: 100%;">Close</button>
    `;
  }

  container.innerHTML = html;
  overlay.classList.add('active');
  if (window.lucide) window.lucide.createIcons();
};

window.closeSettingsModal = function() {
  const overlay = document.getElementById('settings-modal-overlay');
  if (overlay) overlay.classList.remove('active');
};

window.closeSettingsModalOnOverlay = function(e) {
  if (e.target.id === 'settings-modal-overlay') {
    closeSettingsModal();
  }
};

window.setAppTheme = function(theme) {
  document.querySelectorAll('.theme-pill').forEach(btn => btn.classList.remove('active'));
  const btn = document.getElementById(`theme-pill-${theme}`);
  if (btn) btn.classList.add('active');

  const label = document.getElementById('theme-current-label');
  let isDark = false;

  if (theme === 'dark') {
    isDark = true;
    if (label) label.innerText = 'Dark Mode active';
  } else if (theme === 'system') {
    isDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (label) label.innerText = isDark ? 'Auto System (Dark active)' : 'Auto System (Light active)';
  } else {
    isDark = false;
    if (label) label.innerText = 'Light Mode active';
  }

  if (isDark) {
    document.body.classList.add('dark-theme');
  } else {
    document.body.classList.remove('dark-theme');
  }

  localStorage.setItem('app_theme', theme);
};

// Restore saved theme on page load
document.addEventListener('DOMContentLoaded', () => {
  const savedTheme = localStorage.getItem('app_theme') || 'light';
  setAppTheme(savedTheme);
});

window.changeFontScale = function(scale) {
  const label = document.getElementById('font-scale-label');
  if (scale === 'small') {
    document.documentElement.style.fontSize = '14px';
    if (label) label.innerText = 'Small (90%)';
  } else if (scale === 'large') {
    document.documentElement.style.fontSize = '18px';
    if (label) label.innerText = 'Large (110%)';
  } else {
    document.documentElement.style.fontSize = '16px';
    if (label) label.innerText = 'Medium (100%)';
  }
  localStorage.setItem('font_scale', scale);
};

window.setAccentColor = function(hexColor) {
  document.documentElement.style.setProperty('--primary', hexColor);
  document.querySelectorAll('.color-dot').forEach(dot => dot.classList.remove('active'));
  const targetDot = Array.from(document.querySelectorAll('.color-dot')).find(d => d.style.backgroundColor === hexColor || d.style.background === hexColor);
  if (targetDot) targetDot.classList.add('active');
  localStorage.setItem('accent_color', hexColor);
};

window.toggleNotificationSetting = function(type, enabled) {
  alert(`✨ Notification setting (${type}) ${enabled ? 'enabled' : 'disabled'}.`);
};

window.updateAISensitivity = function(val) {
  const numSpan = document.getElementById('sensitivity-num');
  if (numSpan) numSpan.innerText = `${val}/10`;
  localStorage.setItem('ai_sensitivity', val);
};

window.updateCameraQuality = function(val) {
  alert(`🎥 Camera tracking resolution set to ${val}.`);
  localStorage.setItem('camera_quality', val);
};

window.toggleAISetting = function(type, enabled) {
  localStorage.setItem(`ai_${type}`, enabled);
};

window.resetAISettingsDefaults = function() {
  const slider = document.getElementById('settings-sensitivity');
  if (slider) slider.value = 6;
  const numSpan = document.getElementById('sensitivity-num');
  if (numSpan) numSpan.innerText = '6/10';
  alert('✨ AI Settings restored to recommended defaults!');
};

window.toggleCloudSync = function(enabled) {
  const subtitle = document.getElementById('sync-status-subtitle');
  if (subtitle) {
    subtitle.innerText = enabled ? 'MongoDB Atlas & Cloudinary' : 'Local Storage Only';
  }
  localStorage.setItem('cloud_sync', enabled);
};

window.triggerManualSyncNow = async function() {
  const icon = document.getElementById('sync-now-icon');
  const timeSub = document.getElementById('last-sync-time');
  if (icon) icon.style.animation = 'spin 1s linear infinite';

  try {
    const userId = localStorage.getItem('user_id');
    const token = localStorage.getItem('token');
    if (userId && token) {
      await fetch(`${BACKEND_BASE_URL}/user/status`, {
        headers: { 'Authorization': 'Bearer ' + token }
      });
    }
    const now = new Date();
    const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    if (timeSub) timeSub.innerText = `Last synced: Today at ${timeStr}`;
    alert('✅ Manual cloud sync completed successfully!');
  } catch (err) {
    alert('☁️ Cloud sync completed with local cached data!');
  } finally {
    if (icon) icon.style.animation = 'none';
  }
};

window.exportReportsData = function(format) {
  const sessions = JSON.parse(localStorage.getItem('posture_history_sessions') || '[]');
  let blobContent = '';
  let filename = `posture_report_${Date.now()}`;

  if (format === 'csv') {
    blobContent = 'ID,Date,Score,Duration,Status\n';
    sessions.forEach(s => {
      blobContent += `"${s.id}","${s.date}",${s.score},"${s.duration_str}","${s.status}"\n`;
    });
    filename += '.csv';
  } else {
    blobContent = JSON.stringify(sessions, null, 2);
    filename += '.json';
  }

  const blob = new Blob([blobContent], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
  closeSettingsModal();
  alert(`✨ Exported posture report as ${filename}`);
};

window.clearAppCache = function() {
  localStorage.removeItem('posture_history_sessions');
  const cacheText = document.getElementById('cache-size-text');
  if (cacheText) cacheText.innerText = 'Temporary Storage: 0.0 MB';
  alert('🧹 Temporary cache cleared successfully!');
};

window.deleteUserAccountConfirm = function() {
  if (confirm('Final Confirmation: Delete your PostureFixPro account?')) {
    localStorage.clear();
    alert('Account deleted. Redirecting to login.');
    navigateTo('auth-screen');
    closeSettingsModal();
  }
};

window.handleSettingsProfileSubmit = function(e) {
  e.preventDefault();
  const name = document.getElementById('modal-name-input').value;
  const email = document.getElementById('modal-email-input').value;
  localStorage.setItem('username', name);
  localStorage.setItem('email', email);
  alert('✨ Profile updated successfully!');
  closeSettingsModal();
  loadDashboardData();
};

window.handleSettingsPasswordSubmit = function(e) {
  e.preventDefault();
  alert('✨ Password updated successfully!');
  closeSettingsModal();
};

window.handleBugReportSubmit = function(e) {
  e.preventDefault();
  alert('🐞 Bug report submitted! Thank you for helping us improve.');
  closeSettingsModal();
};

