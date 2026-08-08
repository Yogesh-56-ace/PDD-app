import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/base_layout.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'AI Camera Monitoring',
      'subtitle': 'Real-time webcam posture tracking using high-precision skeletal keypoint estimation.',
      'icon': LucideIcons.camera,
    },
    {
      'title': 'Analytics & Progress',
      'subtitle': 'Track your posture score over time with detailed session reports and weekly insights.',
      'icon': LucideIcons.lineChart,
    },
  ];

  void _finishOnboarding() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.completeOnboarding();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      backgroundColor: AppColors.bgApp,
      safeAreaTop: true,
      body: Padding(
        padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text('Skip', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight,
                          ),
                          child: Icon(slide['icon'] as IconData, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide['title'] as String,
                          style: AppTextStyles.h1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide['subtitle'] as String,
                          style: AppTextStyles.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : AppColors.accentGrayDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                icon: LucideIcons.chevronRight,
                onPressed: () {
                  if (_currentPage < _slides.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _finishOnboarding();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }
}
