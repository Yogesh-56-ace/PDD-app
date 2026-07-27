class SettingsModel {
  final double sensitivity;
  final bool soundAlerts;
  final bool vibrationAlerts;
  final int alertDelaySeconds;
  final bool darkMode;

  SettingsModel({
    this.sensitivity = 0.7,
    this.soundAlerts = true,
    this.vibrationAlerts = true,
    this.alertDelaySeconds = 3,
    this.darkMode = false,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      sensitivity: (json['sensitivity'] as num?)?.toDouble() ?? 0.7,
      soundAlerts: json['sound_alerts'] ?? true,
      vibrationAlerts: json['vibration_alerts'] ?? true,
      alertDelaySeconds: json['alert_delay_seconds'] ?? 3,
      darkMode: json['dark_mode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sensitivity': sensitivity,
      'sound_alerts': soundAlerts,
      'vibration_alerts': vibrationAlerts,
      'alert_delay_seconds': alertDelaySeconds,
      'dark_mode': darkMode,
    };
  }
}
