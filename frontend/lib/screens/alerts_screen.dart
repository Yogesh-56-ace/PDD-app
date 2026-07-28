import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/base_layout.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  final List<Map<String, dynamic>> _mockAlerts = const [
    {
      'title': 'Forward Head Position',
      'message': 'Neck tilt exceeded 18° for more than 3 seconds during session.',
      'time': '10 minutes ago',
      'type': 'warning',
    },
    {
      'title': 'Shoulder Misalignment',
      'message': 'Left shoulder dropped 6.2cm below right shoulder level.',
      'time': '1 hour ago',
      'type': 'alert',
    },
    {
      'title': 'Great Ergonomic Streak!',
      'message': 'Maintained 95%+ posture score for 45 consecutive minutes.',
      'time': '3 hours ago',
      'type': 'info',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Alerts & Notifications',
      padding: const EdgeInsets.all(20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Real-time feedback & posture breakdown log', style: AppTextStyles.bodyMuted),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _mockAlerts.length,
              itemBuilder: (context, index) {
                final alert = _mockAlerts[index];
                final type = alert['type'] as String;
                final color = type == 'alert'
                    ? AppColors.alert
                    : (type == 'warning' ? AppColors.warning : AppColors.primary);
                final bgColor = type == 'alert'
                    ? AppColors.alertLight
                    : (type == 'warning' ? AppColors.warningLight : AppColors.primaryLight);
                final icon = type == 'alert'
                    ? LucideIcons.alertTriangle
                    : (type == 'warning' ? LucideIcons.alertCircle : LucideIcons.checkCircle);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [AppColors.shadowCard],
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert['title'] as String, style: AppTextStyles.h3.copyWith(fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(alert['message'] as String, style: AppTextStyles.body.copyWith(fontSize: 12)),
                            const SizedBox(height: 6),
                            Text(alert['time'] as String, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
