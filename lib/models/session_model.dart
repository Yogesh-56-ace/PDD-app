class SessionModel {
  final String sessionId;
  final String startTime;
  final String? endTime;
  final int durationSeconds;
  final int score;
  final int slouchedSeconds;
  final int alertCount;

  SessionModel({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.score,
    required this.slouchedSeconds,
    required this.alertCount,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['session_id'] ?? json['id'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      durationSeconds: json['duration_seconds'] ?? 0,
      score: json['score'] ?? json['posture_score'] ?? 100,
      slouchedSeconds: json['slouched_seconds'] ?? 0,
      alertCount: json['alert_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'start_time': startTime,
      'end_time': endTime,
      'duration_seconds': durationSeconds,
      'score': score,
      'slouched_seconds': slouchedSeconds,
      'alert_count': alertCount,
    };
  }
}
