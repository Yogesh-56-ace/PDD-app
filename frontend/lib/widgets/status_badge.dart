import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final bool isGood;

  const StatusBadge({
    super.key,
    required this.label,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isGood ? AppColors.primaryLight : AppColors.alertLight;
    final textColor = isGood ? AppColors.primary : AppColors.alert;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
