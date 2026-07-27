class AlertModel {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final String type; // 'warning', 'info', 'alert'

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = 'warning',
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Posture Alert',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? '',
      type: json['type'] ?? 'warning',
    );
  }
}
