class StatsModel {
  final int averageScore;
  final int totalSessions;
  final int totalMinutes;
  final List<int> weeklyScores;
  final Map<String, dynamic> breakdown;

  StatsModel({
    required this.averageScore,
    required this.totalSessions,
    required this.totalMinutes,
    required this.weeklyScores,
    required this.breakdown,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      averageScore: json['average_score'] ?? 85,
      totalSessions: json['total_sessions'] ?? 0,
      totalMinutes: json['total_minutes'] ?? 0,
      weeklyScores: List<int>.from(json['weekly_scores'] ?? [82, 88, 90, 85, 92, 89, 94]),
      breakdown: json['breakdown'] ?? {'good': 75, 'slouched': 20, 'absent': 5},
    );
  }
}
