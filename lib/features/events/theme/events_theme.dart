import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class EventsTheme {
  // Brand Teal
  static const Color primary = AppColors.primary;
  static const Color onPrimary = Colors.white;
  static const Color accent = AppColors.primaryMid;
  
  static const Color destructive = AppColors.danger;

  // Adaptive palette (Light mode foundation)
  static const Color background = AppColors.background;
  static const Color cardBackground = AppColors.surface;
  static const Color cardStroke = AppColors.border;
  static const Color foreground = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;

  // Typography (Standardized to Inter)
  static const String headingFont = 'Inter';
  static const String bodyFont = 'Inter';
  
  // Brand Gradient
  static const LinearGradient brandGradient = LinearGradient(
    colors: [AppColors.primary, Color(0xFF00D1ED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
