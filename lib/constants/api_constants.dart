import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  static const String localhostUrl = 'http://localhost:5000/api';

  // Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get userStatus => '$baseUrl/user/status';
  static String get onboarding => '$baseUrl/user/onboarding';
  static String get profile => '$baseUrl/user/profile';
  static String get sessionStart => '$baseUrl/session/start';
  static String get sessionEnd => '$baseUrl/session/end';
  static String get sessions => '$baseUrl/sessions';
  static String get statsWeekly => '$baseUrl/stats/weekly';
  static String get settings => '$baseUrl/settings';
  static String get alerts => '$baseUrl/alerts';
}
