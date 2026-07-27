import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle fontSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textMain,
    double? height,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle fontMono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textMain,
  }) {
    return GoogleFonts.rajdhani(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle h1 = fontSans(fontSize: 24, fontWeight: FontWeight.w700);
  static TextStyle h2 = fontSans(fontSize: 20, fontWeight: FontWeight.w700);
  static TextStyle h3 = fontSans(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle body = fontSans(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle bodyMain = fontSans(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle bodyMuted = fontSans(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMuted);
  static TextStyle caption = fontSans(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted);
  static TextStyle button = fontSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
}
