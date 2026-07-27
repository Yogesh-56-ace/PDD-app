import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<UserModel?> checkStatus() async {
    try {
      final res = await ApiService.get(ApiConstants.userStatus);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = UserModel.fromJson(data);
        await StorageService.saveUser(
          id: user.id,
          name: user.name,
          email: user.email,
          onboardingCompleted: user.onboardingCompleted,
        );
        return user;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final res = await ApiService.post(ApiConstants.login, {
        'email': cleanEmail,
        'password': password,
      });

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        await StorageService.saveToken(data['token']);
        final user = UserModel.fromJson(data['user'] ?? data);
        await StorageService.saveUser(
          id: user.id,
          name: user.name,
          email: user.email,
          onboardingCompleted: user.onboardingCompleted,
        );
        return {'success': true, 'user': user};
      }
      return {'success': false, 'error': data['error'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    int? age,
    String? gender,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final res = await ApiService.post(ApiConstants.register, {
        'name': username,
        'email': cleanEmail,
        'password': password,
        'age': age,
        'gender': gender,
      });

      final data = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        if (data['token'] != null) {
          await StorageService.saveToken(data['token']);
        }
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'error': data['error'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<bool> completeOnboarding() async {
    try {
      final res = await ApiService.post(ApiConstants.onboarding, {});
      if (res.statusCode == 200) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}
