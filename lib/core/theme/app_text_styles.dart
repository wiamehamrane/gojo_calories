import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text styles are getters so they always pick up the active theme's colors.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get heroNumber => TextStyle(
    fontSize: 48, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.0,
  );

  static TextStyle get screenTitle => TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  static TextStyle get sectionHeader => TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  static TextStyle get cardHeading => TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  static TextStyle get cardValue => TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.1,
  );

  static TextStyle get macroValue => TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  static TextStyle get macroLabel => TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  static TextStyle get navLabelActive => TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.0,
  );

  static TextStyle get navLabelInactive => TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.inactive, height: 1.0,
  );

  static TextStyle get bodyBold => TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );

  static TextStyle get bodyRegular => TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  static const buttonLabel = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white, height: 1.0,
  );
}
