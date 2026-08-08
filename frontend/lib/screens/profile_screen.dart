import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';

import '../services/ai_analysis_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _profileImagePath;
  bool _isUploading = false;
  int _sessionsCount = 0;
  int _avgScore = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedAvatar();
    _loadProfileStats();
  }

  Future<void> _loadProfileStats() async {
    final stats = await AiAnalysisService.fetchStats(timeframe: 'all');
    if (stats != null && mounted) {
      setState(() {
        _sessionsCount = stats['total_sessions'] ?? 0;
        _avgScore = stats['avg_score'] ?? 0;
      });
    }
  }

  Future<void> _loadSavedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('user_profile_image');
    });
  }

  Future<void> _pickProfileAvatar() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return; // User cancelled

      setState(() {
        _isUploading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_image', pickedFile.path);

      if (mounted) {
        setState(() {
          _profileImagePath = pickedFile.path;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Profile picture updated successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: $e'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final userName = user?.name ?? 'Posture Pro User';
    final userEmail = user?.email ?? 'user@example.com';
    final avatarLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'Y';

    ImageProvider? avatarImage;
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      if (_profileImagePath!.startsWith('http')) {
        avatarImage = NetworkImage(_profileImagePath!);
      } else {
        avatarImage = FileImage(File(_profileImagePath!));
      }
    }

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
                GestureDetector(
                  onTap: _pickProfileAvatar,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight,
                          border: Border.all(color: AppColors.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: avatarImage != null
                              ? DecorationImage(
                                  image: avatarImage,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarImage == null
                            ? Center(
                                child: Text(
                                  avatarLetter,
                                  style: AppTextStyles.fontMono(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (_isUploading)
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.4),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
                    _buildStatBox('Sessions', '$_sessionsCount', LucideIcons.video),
                    _buildStatBox('Avg Score', _avgScore > 0 ? '$_avgScore%' : 'No Data', LucideIcons.award),
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
