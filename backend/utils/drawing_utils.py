import cv2

def draw_skeleton(frame, landmarks, mp_pose, status='Good Posture'):
    """
    Draws custom joints and connection paths on the webcam frame.
    Color codes the drawing depending on posture state:
      - Green: Good Posture
      - Red: Bad Posture (Slouching / Forward Neck)
    """
    if not landmarks:
        return

    # Set theme colors (BGR format)
    color = (129, 185, 16) if status == 'Good Posture' else (68, 68, 239) # Emerald Green vs. Soft Red
    thickness = 3

    # Define landmark indices
    h, w, _ = frame.shape
    
    def get_coords(landmark):
        return int(landmark.x * w), int(landmark.y * h)

    try:
        # Core posture markers
        l_shoulder = landmarks[11]
        r_shoulder = landmarks[12]
        l_ear = landmarks[7]
        r_ear = landmarks[8]
        l_hip = landmarks[23]
        r_hip = landmarks[24]

        # Convert to screen coordinates
        p_l_shoulder = get_coords(l_shoulder)
        p_r_shoulder = get_coords(r_shoulder)
        p_l_ear = get_coords(l_ear)
        p_r_ear = get_coords(r_ear)
        p_l_hip = get_coords(l_hip)
        p_r_hip = get_coords(r_hip)

        # Midpoints for spine/neck segments
        mid_shoulder = (int((p_l_shoulder[0] + p_r_shoulder[0]) / 2), int((p_l_shoulder[1] + p_r_shoulder[1]) / 2))
        mid_ear = (int((p_l_ear[0] + p_r_ear[0]) / 2), int((p_l_ear[1] + p_r_ear[1]) / 2))
        mid_hip = (int((p_l_hip[0] + p_r_hip[0]) / 2), int((p_l_hip[1] + p_r_hip[1]) / 2))

        # 1. Draw Connection Lines
        cv2.line(frame, p_l_shoulder, p_r_shoulder, color, thickness) # Shoulders
        cv2.line(frame, p_l_hip, p_r_hip, color, thickness)             # Hips
        cv2.line(frame, mid_shoulder, mid_ear, color, thickness)       # Neck segment
        cv2.line(frame, mid_shoulder, mid_hip, color, thickness)       # Spine segment

        # 2. Draw Joints (Nodes)
        for point in [p_l_shoulder, p_r_shoulder, p_l_hip, p_r_hip, mid_ear, mid_shoulder, mid_hip]:
            cv2.circle(frame, point, 7, (255, 255, 255), -1) # inner fill
            cv2.circle(frame, point, 8, color, 2)            # colored outer ring
            
    except Exception as e:
        print(f"Error rendering posture skeleton: {e}")

def draw_hud_overlay(frame, status, neck_angle, spine_angle, reasons):
    """
    Overlays posture diagnostic text, HUD badges, and warning bars directly on the webcam stream.
    """
    h, w, _ = frame.shape
    
    # 1. Outer Border Highlight
    border_color = (129, 185, 16) if status == 'Good Posture' else (68, 68, 239)
    border_thickness = 4
    cv2.rectangle(frame, (0, 0), (w, h), border_color, border_thickness)

    # 2. Status Banner Box
    banner_bg_color = (129, 185, 16) if status == 'Good Posture' else (68, 68, 239)
    cv2.rectangle(frame, (0, 0), (w, 50), banner_bg_color, -1)

    # Text overlays
    status_text = "POSTURE STATE: GOOD" if status == 'Good Posture' else "WARNING: POOR POSTURE DETECTED!"
    cv2.putText(frame, status_text, (20, 32), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2, cv2.LINE_AA)

    # 3. Angle telemetry indicators (Bottom overlay)
    cv2.rectangle(frame, (0, h - 45), (w, h), (0, 0, 0), -1) # opaque bottom bar
    
    telemetry_str = f"Neck Deviation: {neck_angle:.1f} deg | Spine Deviation: {spine_angle:.1f} deg"
    cv2.putText(frame, telemetry_str, (15, h - 16), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1, cv2.LINE_AA)

    # 4. In incorrect state: Draw sub-alert description block
    if status != 'Good Posture' and reasons:
        y_offset = 80
        for reason in reasons[:2]: # Show up to two reasons to prevent cluttering
            # Subtle back plate for alert text readability
            cv2.rectangle(frame, (15, y_offset - 20), (w - 15, y_offset + 10), (0, 0, 0), -1)
            cv2.putText(frame, f"* {reason}", (25, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (100, 100, 255), 1, cv2.LINE_AA)
            y_offset += 35
