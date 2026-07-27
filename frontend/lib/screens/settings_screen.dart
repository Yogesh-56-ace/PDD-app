import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
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
  double _alertDelay = 3.0;

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
          ],
        ),
      ),
    );
  }
}
