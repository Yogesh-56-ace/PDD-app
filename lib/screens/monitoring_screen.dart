import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/posture_provider.dart';
import '../widgets/status_badge.dart';

import '../widgets/custom_app_bar.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostureProvider>(context, listen: false).startMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    final posture = Provider.of<PostureProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: 'AI Monitoring',
        backgroundColor: Colors.black,
        onBack: () {
          posture.stopMonitoring();
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Simulated Camera Feed & Skeletal Canvas
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFF1E293B),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.camera,
                      size: 64,
                      color: posture.isBadPosture ? AppColors.alert : AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI Camera Feed Active',
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time pose tracking & skeletal overlay',
                      style: AppTextStyles.caption.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // Top Header Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      posture.stopMonitoring();
                      Navigator.pop(context);
                    },
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.timer, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          posture.formattedTimer,
                          style: AppTextStyles.fontMono(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: posture.isBadPosture ? 'Slouching Detected' : 'Optimal Posture',
                    isGood: !posture.isBadPosture,
                  ),
                ],
              ),
            ),

            // Bottom Metrics Overlay Card
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [AppColors.shadowCard],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('Neck Angle', '${posture.neckAngle.toStringAsFixed(1)}°', AppColors.primary),
                        _buildMetricCol('Spine Angle', '${posture.spineAngle.toStringAsFixed(1)}°', AppColors.primary),
                        _buildMetricCol('Shoulder Tilt', '${posture.shoulderAngle.toStringAsFixed(1)}°', AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.alert,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        posture.stopMonitoring();
                        Navigator.pop(context);
                      },
                      child: Text('Stop Monitoring', style: AppTextStyles.button),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.fontMono(fontSize: 18, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
