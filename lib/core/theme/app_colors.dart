import 'package:flutter/material.dart';

class AppColors {
  // ── Backgrounds & Surfaces ────────────────────────────────
  static const Color background       = Color(0xFFF2F2F7); // screen bg (iOS system gray)
  static const Color surface          = Color(0xFFFFFFFF); // card bg
  static const Color surfaceMuted     = Color(0xFFF5F5F5); // inner tiles, exercise rows
  static const Color surfaceTealLight = Color(0xFFE0F8FB); // teal-tinted bg (chip active)

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFF0A0A0A);
  static const Color textSecondary    = Color(0xFF6B6B6B);
  static const Color textPlaceholder  = Color(0xFFADADAD);

  // ── Borders & Dividers ────────────────────────────────────
  static const Color border           = Color(0xFFE8E8E8);
  static const Color ringTrack        = Color(0xFFEBEBEB);
  static const Color inactive         = Color(0xFF9E9E9E);

  // ── Primary Teal Palette ──────────────────────────────────
  static const Color primary          = Color(0xFF00B4CC); // main teal
  static const Color primaryDark      = Color(0xFF007D8F); // CTA buttons, FAB
  static const Color primaryLight     = Color(0xFFE0F8FB); // selected chip bg
  static const Color primaryMid       = Color(0xFF00A0B4); // calorie ring arc fill

  // ── Macro Semantic Colors ─────────────────────────────────
  static const Color fire             = Color(0xFFFF7A00); // streak, flame icon
  static const Color fireLight        = Color(0xFFFFA726); // streak dot filled
  static const Color protein          = Color(0xFFFF6B6B); // salmon-red
  static const Color carbs            = Color(0xFFD4A017); // wheat-gold
  static const Color fats             = Color(0xFF8B6FD4); // soft violet

  // ── States ────────────────────────────────────────────────
  static const Color danger           = Color(0xFFE53935); // selected date, errors
  static const Color streakInactive   = Color(0xFFD9D9D9);
}
