import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/theme_provider.dart';
import '../widgets/base_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _sensitivity = 0.6;
  bool _soundAlerts = true;
  bool _vibrationAlerts = true;
  bool _cloudSync = true;
  bool _autoSave = true;
  bool _postureReminders = true;
  String _cameraResolution = '720p (Recommended)';

  void _showModalSheet({
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
    Widget? trailing,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: AppTextStyles.caption),
          trailing: trailing ?? const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 52, color: AppColors.accentGray),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return BaseLayout(
      title: 'Settings Suite',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Account Section
            Text('Account Settings', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: LucideIcons.userCheck,
                    title: 'Edit Profile',
                    subtitle: 'Name, email & profile photo',
                    onTap: () => _showModalSheet(
                      context: context,
                      title: 'Edit Profile',
                      icon: LucideIcons.userCheck,
                      description: 'Update profile details',
                      bodyWidgets: [
                        Text('• Name: Yogesh', style: AppTextStyles.body),
                        const SizedBox(height: 8),
                        Text('• Email: yogesh@posturefixpro.com', style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  _buildSettingTile(
                    icon: LucideIcons.keyRound,
                    title: 'Change Password',
                    subtitle: 'Update security credentials',
                    onTap: () => _showModalSheet(
                      context: context,
                      title: 'Change Password',
                      icon: LucideIcons.keyRound,
                      description: 'Security settings',
                      bodyWidgets: [
                        Text('Password security is managed via TLS 1.3 JWT tokens.', style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  _buildSettingTile(
                    icon: LucideIcons.userX,
                    title: 'Delete Account',
                    subtitle: 'Permanently erase data & metrics',
                    iconColor: AppColors.alert,
                    isLast: true,
                    onTap: () => _showModalSheet(
                      context: context,
                      title: 'Delete Account',
                      icon: LucideIcons.userX,
                      description: 'Permanent Action Warning',
                      bodyWidgets: [
                        Text('Deleting account will permanently wipe all local and cloud data.', style: AppTextStyles.body.copyWith(color: AppColors.alert)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Appearance
            Text('Appearance', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: SwitchListTile(
                title: Text('Dark Theme', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Enable dark mode UI styling', style: AppTextStyles.caption),
                value: theme.isDarkMode,
                activeColor: AppColors.primary,
                onChanged: (val) => theme.toggleDarkMode(val),
              ),
            ),
            const SizedBox(height: 24),

            // 3. AI & Posture Engine
            Text('AI & Posture Engine', style: AppTextStyles.h3),
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
                      Text('Detection Sensitivity', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      Text('${(_sensitivity * 10).toInt()}/10', style: AppTextStyles.fontMono(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Slider(
                    value: _sensitivity,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _sensitivity = val),
                  ),
                  Text('Higher sensitivity alerts slumping earlier.', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Sync & Storage
            Text('Sync & Storage', style: AppTextStyles.h3),
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
                    title: Text('Cloud Data Sync', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('MongoDB Atlas session syncing', style: AppTextStyles.caption),
                    value: _cloudSync,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _cloudSync = val),
                  ),
                  const Divider(height: 1, color: AppColors.accentGray),
                  _buildSettingTile(
                    icon: LucideIcons.refreshCw,
                    title: 'Sync Now',
                    subtitle: 'Trigger manual cloud sync',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Cloud Sync Completed Successfully!')),
                      );
                    },
                  ),
                  _buildSettingTile(
                    icon: LucideIcons.trash2,
                    title: 'Clear Cache',
                    subtitle: 'Temporary Cache: 4.2 MB',
                    iconColor: AppColors.warning,
                    isLast: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🧹 Local Cache Cleared!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Diagnostics & Info
            Text('Diagnostics & Info', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: LucideIcons.cpu,
                    title: 'AI Model Version',
                    subtitle: 'MediaPipe Pose v0.10 (33 Landmarks)',
                    onTap: () {},
                  ),
                  _buildSettingTile(
                    icon: LucideIcons.server,
                    title: 'Backend API Status',
                    subtitle: '🟢 http://localhost:5000/api Online',
                    onTap: () {},
                  ),
                  _buildSettingTile(
                    icon: LucideIcons.info,
                    title: 'About PostureFixPro',
                    subtitle: 'v1.0.0 (Build 104) • Flutter & MediaPipe',
                    isLast: true,
                    onTap: () => _showModalSheet(
                      context: context,
                      title: 'About PostureFixPro',
                      icon: LucideIcons.info,
                      description: 'v1.0.0 (Build 104) • MediaPipe AI',
                      bodyWidgets: [
                        Text('AI-Powered Posture Monitoring System', style: AppTextStyles.body),
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
