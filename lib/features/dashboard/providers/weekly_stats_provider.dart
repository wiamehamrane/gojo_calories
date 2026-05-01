import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/selected_date_provider.dart';

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
  // Use the selected date as "today" so the chart reflects the user's timezone
  final selectedDate = ref.watch(selectedDateProvider);
  final localToday =
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  try {
    final tzOffset = selectedDate.timeZoneOffset.inMinutes;
    final response = await ApiClient.instance.get(
      'stats/weekly',
      queryParameters: {
        'local_today': localToday,
        'tz_offset': tzOffset,
      },
    );
    final List<dynamic> data = response.data ?? [];

    // data is already in ascending order (oldest → newest, 7 entries)
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
    // fallback empty
    return const WeeklyStatsData(
      calorieSpots: [],
      proteinSpots: [],
      carbsSpots: [],
      fatSpots: [],
    );
  }
});
