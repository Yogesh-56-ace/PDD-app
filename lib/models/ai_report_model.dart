class ExerciseModel {
  final String title;
  final String duration;
  final String target;
  final String description;

  ExerciseModel({
    required this.title,
    required this.duration,
    required this.target,
    required this.description,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      title: json['title'] ?? '',
      duration: json['duration'] ?? '',
      target: json['target'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class AiReportModel {
  final String id;
  final String type; // image, video, live
  final String date;
  final String mediaUrl;
  final String skeletonOverlayUrl;
  final int overallScore;
  final double confidenceScore;
  final int landmarksCount;
  final double neckAngle;
  final double shoulderAlignment;
  final double spineAlignment;
  final double hipAlignment;
  final double kneeAlignment;
  final double bodyBalance;
  final bool forwardHeadDetected;
  final bool slouchDetected;
  final List<String> problemsDetected;
  final List<String> healthRisks;
  final List<String> dailyTips;
  final String aiExplanation;
  final List<String> recommendations;
  final List<ExerciseModel> suggestedExercises;

  AiReportModel({
    required this.id,
    required this.type,
    required this.date,
    required this.mediaUrl,
    required this.skeletonOverlayUrl,
    required this.overallScore,
    required this.confidenceScore,
    required this.landmarksCount,
    required this.neckAngle,
    required this.shoulderAlignment,
    required this.spineAlignment,
    required this.hipAlignment,
    required this.kneeAlignment,
    required this.bodyBalance,
    required this.forwardHeadDetected,
    required this.slouchDetected,
    required this.problemsDetected,
    required this.healthRisks,
    required this.dailyTips,
    required this.aiExplanation,
    required this.recommendations,
    required this.suggestedExercises,
  });

  factory AiReportModel.fromJson(Map<String, dynamic> json) {
    return AiReportModel(
      id: json['id'] ?? 'rpt_001',
      type: json['type'] ?? 'image',
      date: json['date'] ?? 'Just now',
      mediaUrl: json['media_url'] ?? '',
      skeletonOverlayUrl: json['skeleton_overlay_url'] ?? '',
      overallScore: json['overall_score'] ?? 88,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 96.2,
      landmarksCount: json['landmarks_count'] ?? 33,
      neckAngle: (json['neck_angle'] as num?)?.toDouble() ?? 14.5,
      shoulderAlignment: (json['shoulder_alignment'] as num?)?.toDouble() ?? 2.1,
      spineAlignment: (json['spine_alignment'] as num?)?.toDouble() ?? 6.8,
      hipAlignment: (json['hip_alignment'] as num?)?.toDouble() ?? 3.2,
      kneeAlignment: (json['knee_alignment'] as num?)?.toDouble() ?? 1.9,
      bodyBalance: (json['body_balance'] as num?)?.toDouble() ?? 96.4,
      forwardHeadDetected: json['forward_head_detected'] ?? false,
      slouchDetected: json['slouch_detected'] ?? false,
      problemsDetected: List<String>.from(json['problems_detected'] ?? ["Forward Head Tilt"]),
      healthRisks: List<String>.from(json['health_risks'] ?? ["Cervical disc strain risk"]),
      dailyTips: List<String>.from(json['daily_tips'] ?? ["Keep feet flat while sitting"]),
      aiExplanation: json['ai_explanation'] ?? "MediaPipe pose analysis complete.",
      recommendations: List<String>.from(json['recommendations'] ?? ["Keep head aligned"]),
      suggestedExercises: (json['suggested_exercises'] as List?)
              ?.map((e) => ExerciseModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
