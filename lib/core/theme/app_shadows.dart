import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.isDark
              ? const Color(0x66000000)
              : const Color(0x0F000000),
          blurRadius: AppColors.isDark ? 16 : 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardElevated => [
        BoxShadow(
          color: AppColors.isDark
              ? const Color(0x73000000)
              : const Color(0x1A000000),
          blurRadius: AppColors.isDark ? 24 : 20,
          offset: const Offset(0, 4),
        ),
        if (!AppColors.isDark)
          const BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
      ];

  static List<BoxShadow> get fabShadow => [
        BoxShadow(
          color: AppColors.isDark
              ? const Color(0x80000000)
              : const Color(0x40000000),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get navShadow => [
        BoxShadow(
          color: AppColors.isDark
              ? const Color(0x66000000)
              : const Color(0x14000000),
          blurRadius: 0,
          offset: const Offset(0, -1),
        ),
      ];
}
