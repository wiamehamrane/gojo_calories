import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class EventsTheme {
  // ── Brand Teal ─────────────────────────────────────────────
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color onPrimary = Colors.white;
  static const Color accent = AppColors.primaryMid;

  static const Color destructive = AppColors.danger;

  // ── Adaptive palette (Light mode) ──────────────────────────
  static const Color background = AppColors.background;
  static const Color cardBackground = AppColors.surface;
  static const Color cardStroke = AppColors.border;
  static const Color foreground = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color surfaceMuted = AppColors.surfaceMuted;

  // ── Typography (Standardized to Inter) ─────────────────────
  static const String headingFont = 'Inter';
  static const String bodyFont = 'Inter';

  // ── Brand Gradient ─────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [AppColors.primary, Color(0xFF00D1ED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF00B4CC), Color(0xFF00D1ED), Color(0xFF62F0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Event Type Colors ───────────────────────────────────────
  static Color eventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return const Color(0xFF00B4CC); // primary teal
      case 'walking':
        return const Color(0xFF4CAF50); // green
      case 'soccer':
        return const Color(0xFFFF7A00); // orange (fire)
      case 'cycling':
        return const Color(0xFF8B6FD4); // violet (fats color)
      case 'swimming':
        return const Color(0xFF2196F3); // blue
      default:
        return const Color(0xFF6B6B6B); // muted
    }
  }

  static Color eventTypeLightColor(String type) {
    return eventTypeColor(type).withValues(alpha: 0.12);
  }

  // ── Shimmer ─────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE8E8E8);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ── Spacing tokens ──────────────────────────────────────────
  static const double pagePadding = 20.0;
  static const double sectionGap = 32.0;
  static const double cardRadius = 20.0;
  static const double inputRadius = 14.0;
  static const double chipRadius = 999.0;
}
