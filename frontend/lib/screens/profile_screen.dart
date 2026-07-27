import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final userName = user?.name ?? 'Posture Pro User';
    final userEmail = user?.email ?? 'user@example.com';
    final avatarLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [AppColors.shadowCard],
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    avatarLetter,
                    style: AppTextStyles.fontMono(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(userName, style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text(userEmail, style: AppTextStyles.bodyMuted),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBox('Sessions', '14', LucideIcons.video),
                    _buildStatBox('Avg Score', '92%', LucideIcons.award),
                    _buildStatBox('Streak', '5 Days', LucideIcons.zap),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.settings, color: AppColors.primary),
                  title: Text('App Settings', style: AppTextStyles.body),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.accentGray),
                ListTile(
                  leading: const Icon(LucideIcons.shield, color: AppColors.primary),
                  title: Text('Privacy & Data', style: AppTextStyles.body),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {},
                ),
                const Divider(height: 1, color: AppColors.accentGray),
                ListTile(
                  leading: const Icon(LucideIcons.helpCircle, color: AppColors.primary),
                  title: Text('Help & Support', style: AppTextStyles.body),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Sign Out',
            icon: LucideIcons.logOut,
            isSecondary: true,
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.fontMono(fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
