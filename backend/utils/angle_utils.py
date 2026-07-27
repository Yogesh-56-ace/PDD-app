import numpy as np

def calculate_angle(a, b, c):
    """
    Calculates the 2D angle (in degrees) formed at vertex b between endpoints a and c.
    Points a, b, c should be tuple/list structures (x, y).
    """
    a = np.array(a)  # First point
    b = np.array(b)  # Vertex point
    c = np.array(c)  # End point

    # Calculate vectors
    ba = a - b
    bc = c - b

    # Cosine formula using dot product and magnitudes
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
    cosine_angle = np.clip(cosine_angle, -1.0, 1.0) # avoid domain errors

    # Retrieve angle in degrees
    angle = np.arccos(cosine_angle)
    return np.degrees(angle)

def calculate_vertical_deviation(a, b):
    """
    Calculates the angle deviation (in degrees) of a segment ab from a true vertical line.
    Useful for neck tilt and spine curvature indicators.
    """
    a = np.array(a)
    b = np.array(b)

    # Vector segment
    segment = a - b
    
    # Absolute vertical vector (0, 1) or (0, -1) depending on segment direction
    vertical = np.array([0, -1] if segment[1] < 0 else [0, 1])

    cosine_angle = np.dot(segment, vertical) / (np.linalg.norm(segment) * np.linalg.norm(vertical) + 1e-6)
    cosine_angle = np.clip(cosine_angle, -1.0, 1.0)

    angle = np.arccos(cosine_angle)
    return np.degrees(angle)
