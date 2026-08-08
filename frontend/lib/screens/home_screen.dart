import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/custom_button.dart';
import 'alerts_screen.dart';
import 'history_screen.dart';
import 'live_camera_screen.dart';
import 'monitoring_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';
import 'upload_image_screen.dart';
import 'upload_video_screen.dart';

import '../services/ai_analysis_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  bool _isLoading = false;
  String _durationStr = '0m';
  int _correctionsVal = 0;
  int? _scoreVal;
  String _statusBadge = 'No Session Data';
  String _statusTitle = 'No Scans Yet';
  String _statusDesc = 'Complete your first AI posture scan or live camera tracking session to view real-time posture analytics.';
  String _emoji = '📊';
  String _aiInsight = 'Take your first AI posture scan or start live webcam tracking to unlock personalized AI ergonomic insights and body alignment analysis.';
  String _recommendedStretch = 'Start a 2-minute live camera tracking session.';
  bool _hasSessions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardStats();
    });
  }

  Future<void> _loadDashboardStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.userId ?? 'user_demo_001';

    final data = await AiAnalysisService.fetchDashboard(userId);

    if (data != null && mounted) {
      setState(() {
        _hasSessions = data['has_sessions'] ?? false;
        _durationStr = data['today_duration_str'] ?? '0m';
        _correctionsVal = data['today_corrections'] ?? 0;
        _scoreVal = data['latest_score'];
        _statusBadge = data['latest_status'] ?? 'No Session Data';
        _statusTitle = data['latest_title'] ?? 'No Scans Yet';
        _statusDesc = data['latest_desc'] ?? 'Complete your first AI posture scan or live camera tracking session to view real-time posture analytics.';
        _emoji = data['emoji'] ?? '📊';
        _aiInsight = data['ai_insight'] ?? 'Take your first AI posture scan or start live webcam tracking to unlock personalized AI ergonomic insights and body alignment analysis.';
        _recommendedStretch = data['recommended_stretch'] ?? 'Start a 2-minute live camera tracking session.';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;
    setState(() => _currentBottomNavIndex = index);
    if (index == 0) {
      _loadDashboardStats();
    }
  }

  Widget _buildBody() {
    switch (_currentBottomNavIndex) {
      case 0:
        return _buildHomeDashboard();
      case 1:
        return UploadImageScreen(
          onBack: () => setState(() => _currentBottomNavIndex = 0),
        );
      case 2:
        return const HistoryScreen();
      case 3:
        return const StatisticsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeDashboard();
    }
  }

  Widget _buildHomeDashboard() {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.user?.name ?? 'User';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Bar Matching Screenshot: Welcome Back, Avatar, Profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDF7E8),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFB8EFCF)),
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Color(0xFF0F9F59),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hello, $userName!',
                        style: AppTextStyles.h2.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _currentBottomNavIndex = 4);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.user, color: AppColors.textMain, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),

          // 2. Dynamic Posture Status Card (Hero Card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: !_hasSessions
                  ? const Color(0xFFF8FAFC)
                  : ((_scoreVal ?? 0) >= 85
                      ? const Color(0xFFE9FAEE)
                      : ((_scoreVal ?? 0) >= 70
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFFEF2F2))),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: !_hasSessions
                    ? const Color(0xFFE2E8F0)
                    : ((_scoreVal ?? 0) >= 85
                        ? const Color(0xFFC3F3D5)
                        : ((_scoreVal ?? 0) >= 70
                            ? const Color(0xFFFED7AA)
                            : const Color(0xFFFCA5A5))),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusBadge,
                        style: TextStyle(
                          color: !_hasSessions
                              ? AppColors.textMuted
                              : ((_scoreVal ?? 0) >= 85
                                  ? const Color(0xFF0F9F59)
                                  : ((_scoreVal ?? 0) >= 70
                                      ? const Color(0xFFC2410C)
                                      : const Color(0xFFDC2626))),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _statusTitle,
                        style: const TextStyle(
                          color: Color(0xFF0C2417),
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusDesc,
                        style: const TextStyle(
                          color: Color(0xFF436553),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _emoji,
                  style: const TextStyle(fontSize: 44),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Two Quick Stats Cards (Session Duration & Corrections)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [AppColors.shadowSoft],
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F8EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.clock, color: Color(0xFF0F9F59), size: 22),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _durationStr,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Session Duration',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [AppColors.shadowSoft],
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF4E5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.sparkles, color: Color(0xFFF97316), size: 22),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$_correctionsVal',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Corrections',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. AI Insight Card (White with Green Left Border)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [AppColors.shadowSoft],
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F9F59),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.zap, color: Color(0xFF0F9F59), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'AI INSIGHT',
                            style: TextStyle(
                              color: Color(0xFF0F9F59),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _aiInsight,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommended Stretch:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _recommendedStretch,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. AI Posture Diagnostic Modes (Image, Video, Live Camera)
          Text('AI Posture Diagnostic Modes', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDiagnosticModeCard(
                  title: 'Upload Image',
                  subtitle: 'MediaPipe 33 Landmark',
                  icon: LucideIcons.image,
                  color: const Color(0xFF0F9F59),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UploadImageScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDiagnosticModeCard(
                  title: 'Upload Video',
                  subtitle: 'Dynamic Movement',
                  icon: LucideIcons.video,
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UploadVideoScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDiagnosticModeCard(
            title: 'Live Camera AI Scan',
            subtitle: 'Real-time 33 Body Landmark Telemetry & Gemini Diagnosis',
            icon: LucideIcons.camera,
            color: const Color(0xFF0F9F59),
            isFullWidth: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveCameraScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // 6. Start Monitoring Button matching screenshot
          CustomButton(
            text: 'Start Monitoring',
            icon: LucideIcons.play,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MonitoringScreen()),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDiagnosticModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: const [AppColors.shadowSoft],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h3.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Disable outer top SafeArea when the current tab manages its own CustomAppBar (e.g. UploadImageScreen)
    final bool tabHasAppBar = _currentBottomNavIndex == 1;

    return Scaffold(
      backgroundColor: AppColors.bgBody,
      body: SafeArea(
        top: !tabHasAppBar,
        bottom: true,
        child: _buildBody(),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}
