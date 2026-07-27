import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

class ApiService {
  static String get baseUrl {
    final port = html.window.location.port;
    // If running on local server (like Live Server or local flutter web port)
    if (port != '5000' && html.window.location.protocol.startsWith('http')) {
      return 'http://localhost:5000/api';
    }
    return '/api';
  }

  // Token management
  static const String _jwtKey = 'pfp_jwt';
  static const String _userKey = 'pfp_user';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jwtKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  static Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jwtKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Authentication endpoints
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      await saveSession(data['token'], data['user']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveSession(data['token'], data['user']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  // Session endpoints
  static Future<List<PostureSession>> getSessions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/sessions?limit=50'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((s) => PostureSession.fromJson(s)).toList();
    } else {
      throw Exception('Failed to load posture sessions');
    }
  }

  static Future<Map<String, dynamic>> savePostureSession(
      double score, double goodPct, double badPct, int alerts, int duration) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'posture_score': score,
        'good_percentage': goodPct,
        'bad_percentage': badPct,
        'alerts_triggered': alerts,
        'duration': duration,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to save posture session');
    }
  }

  // Profile endpoints
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile settings');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    final resData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveSession(token!, resData['user']);
      return resData;
    } else {
      throw Exception(resData['message'] ?? 'Failed to update profile settings');
    }
  }

  // Analytics endpoints
  static Future<Map<String, dynamic>> getAnalytics() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to calculate analytics metrics');
    }
  }
}
