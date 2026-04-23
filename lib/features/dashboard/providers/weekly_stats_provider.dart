import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/network/api_client.dart';

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
  try {
    final response = await ApiClient.instance.get('stats/');
    final List<dynamic> data = response.data ?? [];

    // Stats come in desc order (newest first), so we reverse
    final reversed = data.reversed.toList();

    List<FlSpot> toSpots(String key) {
      return reversed.asMap().entries.map((e) {
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
