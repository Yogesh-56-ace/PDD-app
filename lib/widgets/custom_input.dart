import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class CustomInput extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? errorText;

  const CustomInput({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTextStyles.bodyMuted,
            filled: true,
            fillColor: AppColors.accentGray,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
