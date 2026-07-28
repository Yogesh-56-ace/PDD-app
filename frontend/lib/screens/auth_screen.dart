import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/base_layout.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register Controllers
  final _regUsernameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regAgeController = TextEditingController();
  final _regPasswordController = TextEditingController();
  String _selectedGender = 'Male';

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regAgeController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _onSuccessNavigate(AuthProvider auth) {
    if (auth.isOnboardingCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return BaseLayout(
      backgroundColor: AppColors.bgApp,
      safeAreaTop: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                ),
                child: const Icon(LucideIcons.activity, size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                isLogin ? 'Welcome Back' : 'Create Account',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 6),
              Text(
                isLogin
                    ? 'Log in to track your posture metrics'
                    : 'Start your spine health tracking journey',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 32),
              if (auth.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.alertLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    auth.errorMessage!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.alert),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (isLogin) ...[
                CustomInput(
                  label: 'Gmail ID (Email)',
                  placeholder: 'Enter your Gmail ID',
                  controller: _loginEmailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                CustomInput(
                  label: 'Password',
                  placeholder: 'Enter your password',
                  controller: _loginPasswordController,
                  isPassword: true,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Login',
                  icon: LucideIcons.logIn,
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    final ok = await auth.login(
                      _loginEmailController.text.trim(),
                      _loginPasswordController.text.trim(),
                    );
                    if (ok && mounted) _onSuccessNavigate(auth);
                  },
                ),
              ] else ...[
                CustomInput(
                  label: 'Username',
                  placeholder: 'Pick a username',
                  controller: _regUsernameController,
                ),
                const SizedBox(height: 14),
                CustomInput(
                  label: 'Gmail ID (Email)',
                  placeholder: 'Enter your Gmail ID',
                  controller: _regEmailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomInput(
                        label: 'Age',
                        placeholder: 'Age',
                        controller: _regAgeController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gender', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.accentGray,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: ['Male', 'Female', 'Other']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedGender = val!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CustomInput(
                  label: 'Password',
                  placeholder: 'At least 6 characters',
                  controller: _regPasswordController,
                  isPassword: true,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Create Account',
                  icon: LucideIcons.userPlus,
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    final ok = await auth.register(
                      username: _regUsernameController.text.trim(),
                      email: _regEmailController.text.trim(),
                      password: _regPasswordController.text.trim(),
                      age: int.tryParse(_regAgeController.text.trim()),
                      gender: _selectedGender,
                    );
                    if (ok && mounted) _onSuccessNavigate(auth);
                  },
                ),
              ],
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => isLogin = !isLogin),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMuted,
                    children: [
                      TextSpan(
                        text: isLogin
                            ? "Don't have an account? "
                            : "Already have an account? ",
                      ),
                      TextSpan(
                        text: isLogin ? 'Register here' : 'Login here',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
