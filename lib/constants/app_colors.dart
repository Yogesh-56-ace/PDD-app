import 'package:flutter/material.dart';

class AppColors {
  static const Color bgApp = Color(0xFFFFFFFF);
  static const Color bgBody = Color(0xFFF3F6F5);
  
  static const Color primary = Color(0xFF10B981); // Soft Emerald Green
  static const Color primaryLight = Color(0xFFECFDF5);
  static const Color primaryHover = Color(0xFF059669);
  
  static const Color secondary = Color(0xFF0D9488); // Deep Teal Accent
  static const Color secondaryLight = Color(0xFFF0FDFA);

  static const Color textMain = Color(0xFF1F2937); // Dark Slate
  static const Color textMuted = Color(0xFF6B7280); // Muted Slate Gray
  
  static const Color accentGray = Color(0xFFF3F4F6); // Light Gray
  static const Color accentGrayDark = Color(0xFFE5E7EB);
  
  static const Color alert = Color(0xFFEF4444); // Soft Coral Red
  static const Color alertLight = Color(0xFFFEF2F2);
  
  static const Color alertRed = Color(0xFFEF4444);
  static const Color alertWarning = Color(0xFFF59E0B);
  static const Color accentGreen = Color(0xFF10B981);
  
  static const Color warning = Color(0xFFF59E0B); // Gentle Warm Amber
  static const Color warningLight = Color(0xFFFFFBEB);
  
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF3F4F6);

  static const BoxShadow shadowSoft = BoxShadow(
    color: Color.fromRGBO(16, 185, 129, 0.03),
    blurRadius: 30,
    offset: Offset(0, 10),
  );

  static const BoxShadow shadowCard = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.03),
    blurRadius: 36,
    offset: Offset(0, 12),
  );

  static const BoxShadow shadowButton = BoxShadow(
    color: Color.fromRGBO(16, 185, 129, 0.2),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
}
