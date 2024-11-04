import 'package:flutter/material.dart';
import 'colors.dart';

class AppStyles {
  // Card Decorations
  static final cardDecoration = BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(15),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 6,
        spreadRadius: 2,
      ),
    ],
  );

  static final chipDecoration = BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(20),
  );

  // Text Styles
  static const titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  static const chipTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Button Styles
  static final elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.background,
    padding: const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );

  // Common Padding
  static const defaultPadding = EdgeInsets.all(16.0);
  static const cardPadding = EdgeInsets.all(20.0);
  static const contentSpacing = SizedBox(height: 12);

  // Common Decorations
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }
}