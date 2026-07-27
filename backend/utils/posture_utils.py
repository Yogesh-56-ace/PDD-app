def evaluate_posture(neck_deviation, shoulder_deviation, spine_deviation, sensitivity='medium'):
    """
    Evaluates computed joint angle deviations against clinical thresholds.
    Adjusts tolerances dynamically based on user sensitivity preferences:
      - Low: wider margins (less sensitive to slouching)
      - Medium: standard baseline settings
      - High: tight margins (very sensitive, proactive corrections)
    """
    
    # Configure threshold guidelines
    if sensitivity == 'high':
        neck_threshold = 12.0
        spine_threshold = 15.0
        shoulder_threshold = 6.0
    elif sensitivity == 'low':
        neck_threshold = 22.0
        spine_threshold = 26.0
        shoulder_threshold = 14.0
    else: # medium (standard)
        neck_threshold = 16.0
        spine_threshold = 20.0
        shoulder_threshold = 10.0

    status = "Good Posture"
    reasons = []

    # Assess neck tilt (Forward Head Posture)
    if neck_deviation > neck_threshold:
        status = "Bad Posture"
        reasons.append(f"Neck leaning forward by {neck_deviation:.1f}°")

    # Assess spinal curving (Hunching / Slouching)
    if spine_deviation > spine_threshold:
        status = "Bad Posture"
        reasons.append(f"Back slouching by {spine_deviation:.1f}°")

    # Assess horizontal shoulder slope (Imbalance)
    if shoulder_deviation > shoulder_threshold:
        status = "Bad Posture"
        reasons.append(f"Shoulders uneven by {shoulder_deviation:.1f}°")

    return status, reasons
