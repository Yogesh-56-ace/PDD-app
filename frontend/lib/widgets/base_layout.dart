import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'custom_app_bar.dart';

/// Reusable Base Layout Wrapper for PostureFixPro.
/// Inherited by screens to ensure consistent SafeArea, status bar spacing, and AppBar alignment.
class BaseLayout extends StatelessWidget {
  final String? title;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool resizeToAvoidBottomInset;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final EdgeInsetsGeometry? padding;

  const BaseLayout({
    super.key,
    this.title,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.showBackButton = true,
    this.onBack,
    this.actions,
    this.resizeToAvoidBottomInset = true,
    this.safeAreaTop = false,
    this.safeAreaBottom = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final PreferredSizeWidget? finalAppBar = appBar ??
        (title != null
            ? CustomAppBar(
                title: title!,
                showBackButton: showBackButton,
                onBack: onBack,
                actions: actions,
                backgroundColor: backgroundColor,
              )
            : null);

    Widget content = body;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.bgBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: finalAppBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        top: finalAppBar == null ? safeAreaTop : false,
        bottom: safeAreaBottom,
        child: content,
      ),
    );
  }
}
