import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleGetStarted(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
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
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 120 + (_pulseController.value * 12),
                    height: 120 + (_pulseController.value * 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2 * _pulseController.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(LucideIcons.activity, size: 40, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Posture Fix Pro',
                style: AppTextStyles.h1.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'AI-Powered Posture Monitoring & Correction',
                style: AppTextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              CustomButton(
                text: 'Get Started',
                icon: LucideIcons.chevronRight,
                onPressed: () => _handleGetStarted(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
