import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Distinct accent color per calendar day (cycles through the palette).
class CalendarDayColors {
  static List<Color> get palette => [
    AppColors.primary,
    AppColors.protein,
    AppColors.carbs,
    AppColors.fats,
    const Color(0xFF26A69A),
    const Color(0xFF5C6BC0),
    const Color(0xFFEC407A),
    const Color(0xFF7CB342),
    const Color(0xFFFF7043),
    const Color(0xFFAB47BC),
    const Color(0xFF29B6F6),
    const Color(0xFFFFCA28),
  ];

  static Color forDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return palette[key % palette.length];
  }
}
