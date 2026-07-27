import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isOnboardingCompleted => _user?.onboardingCompleted ?? false;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkBootStatus();
  }

  Future<void> checkBootStatus() async {
    _isLoading = true;
    notifyListeners();

    final token = await StorageService.getToken();
    if (token != null) {
      _user = await AuthService.checkStatus();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.login(email, password);
    _isLoading = false;

    if (result['success'] == true) {
      _user = result['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    int? age,
    String? gender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.register(
      username: username,
      email: email,
      password: password,
      age: age,
      gender: gender,
    );
    _isLoading = false;

    if (result['success'] == true) {
      // Automatically login after successful registration
      return await login(email, password);
    } else {
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }
  }

  Future<void> completeOnboarding() async {
    await AuthService.completeOnboarding();
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        age: _user!.age,
        gender: _user!.gender,
        onboardingCompleted: true,
      );
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.clearSession();
    _user = null;
    notifyListeners();
  }
}
