class PostureSession {
  final String id;
  final double postureScore;
  final double goodPercentage;
  final double badPercentage;
  final int alertsTriggered;
  final int duration;
  final DateTime timestamp;

  PostureSession({
    required this.id,
    required this.postureScore,
    required this.goodPercentage,
    required this.badPercentage,
    required this.alertsTriggered,
    required this.duration,
    required this.timestamp,
  });

  factory PostureSession.fromJson(Map<String, dynamic> json) {
    return PostureSession(
      id: json['_id'] ?? '',
      postureScore: (json['posture_score'] as num?)?.toDouble() ?? 0.0,
      goodPercentage: (json['good_percentage'] as num?)?.toDouble() ?? 0.0,
      badPercentage: (json['bad_percentage'] as num?)?.toDouble() ?? 0.0,
      alertsTriggered: json['alerts_triggered'] ?? 0,
      duration: json['duration'] ?? 10,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIsoformatString()),
    );
  }
}

extension DateTimeIso on DateTime {
  String toIsoformatString() => toIso8601String();
}
