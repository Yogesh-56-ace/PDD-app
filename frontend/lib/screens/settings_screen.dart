import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _sensitivity = 0.7;
  bool _soundAlerts = true;
  bool _vibrationAlerts = true;

  void _showSupportDetail({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String description,
    required List<Widget> bodyWidgets,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.h3),
                        Text(description, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.accentGray),
              const SizedBox(height: 16),
              ...bodyWidgets,
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(icon, color: iconColor, size: 20),
          title: Text(title, style: AppTextStyles.body),
          trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 52, color: AppColors.accentGray),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'App Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitoring Sensitivity', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Detection Strictness', style: AppTextStyles.body),
                      Text('${(_sensitivity * 100).toInt()}%', style: AppTextStyles.fontMono(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Slider(
                    value: _sensitivity,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _sensitivity = val),
                  ),
                  Text('Higher sensitivity triggers slouch alerts earlier.', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Alert Preferences', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Audio Alert Chime', style: AppTextStyles.body),
                    subtitle: Text('Play soft alert sound on bad posture', style: AppTextStyles.caption),
                    value: _soundAlerts,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _soundAlerts = val),
                  ),
                  const Divider(height: 1, color: AppColors.accentGray),
                  SwitchListTile(
                    title: Text('Haptic Vibration', style: AppTextStyles.body),
                    subtitle: Text('Vibrate phone on slouch alert', style: AppTextStyles.caption),
                    value: _vibrationAlerts,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _vibrationAlerts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Appearance', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: SwitchListTile(
                title: Text('Dark Mode', style: AppTextStyles.body),
                subtitle: Text('Use dark theme for posture monitoring', style: AppTextStyles.caption),
                value: theme.isDarkMode,
                activeColor: AppColors.primary,
                onChanged: (val) => theme.toggleDarkMode(val),
              ),
            ),
            const SizedBox(height: 24),
            Text('Support & Information', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildSupportItem(
                    icon: LucideIcons.lifeBuoy,
                    title: 'Help Center',
                    onTap: () => _showSupportDetail(
                      context: context,
                      title: 'Help Center',
                      icon: LucideIcons.lifeBuoy,
                      description: 'Browse articles and FAQs',
                      bodyWidgets: [
                        Text('• Camera Setup Guide', style: AppTextStyles.body),
                        const SizedBox(height: 8),
                        Text('• AI Calibration Tips', style: AppTextStyles.body),
                        const SizedBox(height: 8),
                        Text('• Troubleshooting Alerts', style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  _buildSupportItem(
                    icon: LucideIcons.headphones,
                    title: 'Contact Support',
                    onTap: () => _showSupportDetail(
                      context: context,
                      title: 'Contact Support',
                      icon: LucideIcons.headphones,
                      description: 'Get 24/7 assistance from our team',
                      bodyWidgets: [
                        Text('Email: support@posturefixpro.com', style: AppTextStyles.body),
                        const SizedBox(height: 8),
                        Text('Average Response Time: < 2 hours', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  _buildSupportItem(
                    icon: LucideIcons.messageSquarePlus,
                    title: 'Send Feedback',
                    onTap: () => _showSupportDetail(
                      context: context,
                      title: 'Send Feedback',
                      icon: LucideIcons.messageSquarePlus,
                      description: 'Share your thoughts and requests',
                      bodyWidgets: [
                        Text('We love hearing from our community!', style: AppTextStyles.body),
                        const SizedBox(height: 8),
                        Text('Send feature suggestions or report UI issues anytime.', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  _buildSupportItem(
                    icon: LucideIcons.bookOpen,
                    title: 'User Guide',
                    onTap: () => _showSupportDetail(
                      context: context,
                      title: 'User Guide',
                      icon: LucideIcons.bookOpen,
                      description: 'Learn how to maximize your posture health',
                      bodyWidgets: [
                        Text('1. Place device 2-3 feet away at eye level.', style: AppTextStyles.body),
                        const SizedBox(height: 6),
                        Text('2. Sit upright to calibrate baseline.', style: AppTextStyles.body),
                        const SizedBox(height: 6),
                        Text('3. Receive gentle reminders when slumping.', style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  _buildSupportItem(
                    icon: LucideIcons.star,
                    title: 'Rate Our App',
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () => _showSupportDetail(
                      context: context,
                      title: 'Rate Our App',
                      icon: LucideIcons.star,
                      description: 'Support PostureFixPro with a 5-star rating',
                      bodyWidgets: [
                        const Center(child: Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 28))),
                        const SizedBox(height: 12),
                        Center(child: Text('Thank you for helping us grow!', style: AppTextStyles.body)),
                      ],
                    ),
                  ),
                  _buildSupportItem(
                    icon: LucideIcons.shieldCheck,
                    title: 'Privacy Policy',
                    onTap: () => _showSupportDetail(
                      context: context,
                      title: 'Privacy Policy',
                      icon: LucideIcons.shieldCheck,
                      description: 'On-device AI processing & data encryption',
                      bodyWidgets: [
                        Text('Camera feeds are processed locally on-device. No raw video is stored without consent.', style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  _buildSupportItem(
                    icon: LucideIcons.fileText,
                    title: 'Terms & Conditions',
                    onTap: () => _showSupportDetail(
                      context: context,
                      title: 'Terms & Conditions',
                      icon: LucideIcons.fileText,
                      description: 'App usage & health guidance terms',
                      bodyWidgets: [
                        Text('PostureFixPro provides ergonomic insights and is not a replacement for medical diagnosis.', style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  _buildSupportItem(
                    icon: LucideIcons.info,
                    title: 'About PostureFixPro',
                    isLast: true,
                    onTap: () => _showSupportDetail(
                      context: context,
                      title: 'About PostureFixPro',
                      icon: LucideIcons.info,
                      description: 'v1.0.0 (Build 104) • MediaPipe AI',
                      bodyWidgets: [
                        Text('AI-Powered Posture Monitoring & Correction System.', style: AppTextStyles.body),
                        const SizedBox(height: 6),
                        Text('Built with Flutter, Python Flask & MongoDB Atlas.', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
