import 'dart:math';

class PoseLandmark {
  final double x;
  final double y;
  final double visibility;

  PoseLandmark({required this.x, required this.y, this.visibility = 1.0});
}

class PostureEvaluation {
  final bool isBad;
  final double neckDeviation;
  final double shoulderDeviation;
  final double spineDeviation;

  PostureEvaluation({
    required this.isBad,
    required this.neckDeviation,
    required this.shoulderDeviation,
    required this.spineDeviation,
  });
}

class PoseDetectorService {
  // Calculates 2D angle (in degrees) formed at vertex b between endpoints a and c
  static double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ba = Point(a.x - b.x, a.y - b.y);
    final bc = Point(c.x - b.x, c.y - b.y);

    final dotProduct = ba.x * bc.x + ba.y * bc.y;
    final magBA = sqrt(ba.x * ba.x + ba.y * ba.y);
    final magBC = sqrt(bc.x * bc.x + bc.y * bc.y);

    final cosine = dotProduct / (magBA * magBC + 1e-6);
    final clamped = cosine.clamp(-1.0, 1.0);

    final angleRad = (atan2(bc.y, bc.x) - atan2(ba.y, ba.x)).abs();
    return (angleRad * 180 / pi) % 360;
  }

  // Calculates segment deviation from absolute vertical line
  static double calculateVerticalDeviation(PoseLandmark a, PoseLandmark b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final angle = (atan2(dy, dx) * 180 / pi).abs();
    return (90 - angle).abs();
  }

  // Evaluates posture from ear, shoulder, and hip landmarks
  static PostureEvaluation evaluatePosture({
    required PoseLandmark ear,
    required PoseLandmark shoulder,
    required PoseLandmark hip,
    required PoseLandmark otherShoulder,
  }) {
    final neckDev = calculateVerticalDeviation(ear, shoulder);
    final spineDev = calculateVerticalDeviation(shoulder, hip);
    final shoulderDev = (shoulder.y - otherShoulder.y).abs() * 100;

    // Thresholds: Neck > 18°, Spine > 15°, Shoulder > 5.0
    final isBad = neckDev > 18.0 || spineDev > 15.0 || shoulderDev > 5.0;

    return PostureEvaluation(
      isBad: isBad,
      neckDeviation: neckDev,
      shoulderDeviation: shoulderDev,
      spineDeviation: spineDev,
    );
  }
}
