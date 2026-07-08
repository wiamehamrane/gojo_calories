import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Distinct accent color per calendar day (cycles through the palette).
class CalendarDayColors {
  static const List<Color> palette = [
    AppColors.primary,
    AppColors.protein,
    AppColors.carbs,
    AppColors.fats,
    Color(0xFF26A69A),
    Color(0xFF5C6BC0),
    Color(0xFFEC407A),
    Color(0xFF7CB342),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFF29B6F6),
    Color(0xFFFFCA28),
  ];

  static Color forDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return palette[key % palette.length];
  }
}
