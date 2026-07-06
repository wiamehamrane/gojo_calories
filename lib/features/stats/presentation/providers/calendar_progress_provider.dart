import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

class DayCalorieProgress {
  final int calorieBudget;
  final int caloriesConsumed;

  const DayCalorieProgress({
    required this.calorieBudget,
    required this.caloriesConsumed,
  });

  double get progress =>
      calorieBudget > 0 ? caloriesConsumed / calorieBudget : 0.0;

  bool get isOverGoal =>
      calorieBudget > 0 && caloriesConsumed > calorieBudget;

  static DayCalorieProgress fromMap(Map<String, dynamic> map) {
    return DayCalorieProgress(
      calorieBudget: (map['calorie_budget'] as num?)?.toInt() ?? 0,
      caloriesConsumed: (map['calories_consumed'] as num?)?.toInt() ?? 0,
    );
  }
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

final calendarProgressProvider =
    FutureProvider<Map<String, DayCalorieProgress>>((ref) async {
  final now = DateTime.now();
  final endDate = _dateKey(now);
  final data = await ref.read(statsRepositoryProvider).getCalendarProgress(
        endDate: endDate,
        days: 366,
        tzOffset: now.timeZoneOffset.inMinutes,
      );

  final map = <String, DayCalorieProgress>{};
  for (final item in data) {
    if (item is Map) {
      final m = Map<String, dynamic>.from(item);
      final date = m['date']?.toString();
      if (date != null) {
        map[date] = DayCalorieProgress.fromMap(m);
      }
    }
  }
  return map;
});

DayCalorieProgress? lookupCalendarProgress(
  Map<String, DayCalorieProgress>? data,
  DateTime date,
) {
  if (data == null) return null;
  return data[_dateKey(date)];
}
