import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const heroNumber = TextStyle(
    fontSize: 48, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.0,
  );

  static const screenTitle = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  static const sectionHeader = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  static const cardHeading = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  static const cardValue = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.1,
  );

  static const macroValue = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  static const macroLabel = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  static const navLabelActive = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, 
    color: AppColors.textPrimary, height: 1.0,
  );
  
  static const navLabelInactive = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, 
    color: AppColors.inactive, height: 1.0,
  );

  static const bodyBold = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );

  static const bodyRegular = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  static const buttonLabel = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white, height: 1.0,
  );
}
