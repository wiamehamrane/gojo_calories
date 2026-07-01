import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/di/repository_providers.dart';
import 'selected_date_provider.dart';

class WeeklyStatsData {
  final List<FlSpot> calorieSpots;
  final List<FlSpot> proteinSpots;
  final List<FlSpot> carbsSpots;
  final List<FlSpot> fatSpots;

  const WeeklyStatsData({
    required this.calorieSpots,
    required this.proteinSpots,
    required this.carbsSpots,
    required this.fatSpots,
  });
}

final weeklyStatsProvider = FutureProvider<WeeklyStatsData>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final localToday =
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  try {
    final data = await ref.read(statsRepositoryProvider).getWeeklyStats(
          localToday: localToday,
          tzOffset: selectedDate.timeZoneOffset.inMinutes,
        );

    List<FlSpot> toSpots(String key) {
      return data.asMap().entries.map((e) {
        final val = (e.value[key] ?? 0) as num;
        return FlSpot(e.key.toDouble(), val.toDouble());
      }).toList();
    }

    return WeeklyStatsData(
      calorieSpots: toSpots('calories_consumed'),
      proteinSpots: toSpots('protein_consumed'),
      carbsSpots: toSpots('carbs_consumed'),
      fatSpots: toSpots('fat_consumed'),
    );
  } catch (_) {
    return const WeeklyStatsData(
      calorieSpots: [],
      proteinSpots: [],
      carbsSpots: [],
      fatSpots: [],
    );
  }
});
