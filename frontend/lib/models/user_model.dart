class UserModel {
  final String id;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final bool onboardingCompleted;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.onboardingCompleted = false,
  });

  String get userId => id;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? ''),
      gender: json['gender'],
      onboardingCompleted: json['onboarding_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'onboarding_completed': onboardingCompleted,
    };
  }
}
