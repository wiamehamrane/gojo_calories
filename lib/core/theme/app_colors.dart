import 'package:flutter/material.dart';

/// Brand palette — light and dark derived from the same teal identity.
///
/// Call [applyBrightness] from [MaterialApp.builder] so every existing
/// `AppColors.*` usage switches with the active theme.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;

  static Brightness get brightness => _brightness;

  static bool get isDark => _brightness == Brightness.dark;

  static void applyBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  // ── Light (canonical brand) ───────────────────────────────
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF5F5F5);
  static const Color lightSurfaceTeal = Color(0xFFE0F8FB);
  static const Color lightTextPrimary = Color(0xFF0A0A0A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextPlaceholder = Color(0xFFADADAD);
  static const Color lightBorder = Color(0xFFE8E8E8);
  static const Color lightRingTrack = Color(0xFFEBEBEB);
  static const Color lightInactive = Color(0xFF9E9E9E);
  static const Color lightPrimary = Color(0xFF00B4CC);
  static const Color lightPrimaryDark = Color(0xFF007D8F);
  static const Color lightPrimaryLight = Color(0xFFE0F8FB);
  static const Color lightPrimaryMid = Color(0xFF00A0B4);
  static const Color lightStreakInactive = Color(0xFFD9D9D9);

  // ── Dark (teal-tinted charcoal — same brand, night polish) ─
  static const Color darkBackground = Color(0xFF0B1214);
  static const Color darkSurface = Color(0xFF151D20);
  static const Color darkSurfaceMuted = Color(0xFF1C2629);
  static const Color darkSurfaceTeal = Color(0xFF163035);
  static const Color darkTextPrimary = Color(0xFFF0F5F6);
  static const Color darkTextSecondary = Color(0xFF9AA5A8);
  static const Color darkTextPlaceholder = Color(0xFF6E7A7D);
  static const Color darkBorder = Color(0xFF2A3538);
  static const Color darkRingTrack = Color(0xFF2A3538);
  static const Color darkInactive = Color(0xFF7A8689);
  static const Color darkPrimary = Color(0xFF1AC6DC);
  static const Color darkPrimaryDark = Color(0xFF00B4CC);
  static const Color darkPrimaryLight = Color(0xFF163035);
  static const Color darkPrimaryMid = Color(0xFF14B8CE);
  static const Color darkStreakInactive = Color(0xFF3A4649);

  // ── Semantic accents (shared; slightly lifted in dark) ────
  static const Color fire = Color(0xFFFF7A00);
  static const Color fireLight = Color(0xFFFFA726);
  static const Color protein = Color(0xFFFF6B6B);
  static const Color carbs = Color(0xFFD4A017);
  static const Color fats = Color(0xFF8B6FD4);
  static const Color danger = Color(0xFFE53935);

  static Color get fireActive =>
      isDark ? const Color(0xFFFF8A1A) : fire;
  static Color get fireLightActive =>
      isDark ? const Color(0xFFFFB74D) : fireLight;
  static Color get proteinActive =>
      isDark ? const Color(0xFFFF7A7A) : protein;
  static Color get carbsActive =>
      isDark ? const Color(0xFFE0B020) : carbs;
  static Color get fatsActive =>
      isDark ? const Color(0xFF9B82E0) : fats;
  static Color get dangerActive =>
      isDark ? const Color(0xFFEF5350) : danger;

  // ── Theme-aware getters (used across the app) ─────────────
  static Color get background =>
      isDark ? darkBackground : lightBackground;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get surfaceMuted =>
      isDark ? darkSurfaceMuted : lightSurfaceMuted;
  static Color get surfaceTealLight =>
      isDark ? darkSurfaceTeal : lightSurfaceTeal;

  static Color get textPrimary =>
      isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textPlaceholder =>
      isDark ? darkTextPlaceholder : lightTextPlaceholder;

  static Color get border => isDark ? darkBorder : lightBorder;
  static Color get ringTrack => isDark ? darkRingTrack : lightRingTrack;
  static Color get inactive => isDark ? darkInactive : lightInactive;

  static Color get primary => isDark ? darkPrimary : lightPrimary;
  static Color get primaryDark =>
      isDark ? darkPrimaryDark : lightPrimaryDark;
  static Color get primaryLight =>
      isDark ? darkPrimaryLight : lightPrimaryLight;
  static Color get primaryMid =>
      isDark ? darkPrimaryMid : lightPrimaryMid;

  static Color get streakInactive =>
      isDark ? darkStreakInactive : lightStreakInactive;

  /// Soft hero wash used on coach / profile promo (light pastels → dark teal/ember).
  static List<Color> get heroGradient => isDark
      ? const [
          Color(0xFF102028),
          Color(0xFF0B1214),
          Color(0xFF1A1814),
        ]
      : const [
          Color(0xFFE8FBFE),
          Color(0xFFF2F2F7),
          Color(0xFFFFF6EE),
        ];

  static List<Color> get heroGradientWarm => isDark
      ? const [
          Color(0xFF102028),
          Color(0xFF151D20),
          Color(0xFF1F1A14),
        ]
      : const [
          Color(0xFFE8FBFE),
          Color(0xFFFFFFFF),
          Color(0xFFFFF4EC),
        ];

  static List<Color> get chipGradient => isDark
      ? [
          primary.withValues(alpha: 0.22),
          fire.withValues(alpha: 0.14),
        ]
      : const [
          lightPrimaryLight,
          Color(0xFFFFF0E6),
        ];
}
