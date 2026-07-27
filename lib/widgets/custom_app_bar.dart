import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Reusable Custom Header / AppBar for the Posture Fix Pro Application.
/// Provides a consistent Material 3 back button and title styling across all secondary screens.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBack,
    this.actions,
    this.backgroundColor,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.bgBody,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? Container(
              margin: const EdgeInsets.only(left: 14, top: 10, bottom: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textMain, size: 18),
                tooltip: 'Back',
                onPressed: () {
                  if (onBack != null) {
                    onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMain,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      actions: actions,
    );
  }
}
