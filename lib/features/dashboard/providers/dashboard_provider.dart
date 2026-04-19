import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/network/api_client.dart';
import '../../../core/models/daily_stats.dart' as models;
import '../../../core/database/database_provider.dart';
import '../../../core/database/database.dart';

class DashboardNotifier extends Notifier<models.DailyStats> {
  @override
  models.DailyStats build() {
    _loadData();
    return models.DailyStats(
      calorieBudget: 2200,
      caloriesConsumed: 0,
      proteinConsumed: 0,
      carbsConsumed: 0,
      fatConsumed: 0,
      proteinTarget: 150,
      carbsTarget: 200,
      fatTarget: 65,
    );
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiClient.instance.get('stats/');
      if (response.data is List && response.data.isNotEmpty) {
        final latest = response.data.first;
        final stats = models.DailyStats(
          calorieBudget: latest['calorie_budget'] ?? 2200,
          caloriesConsumed: latest['calories_consumed'] ?? 0,
          proteinConsumed: latest['protein_consumed'] ?? 0,
          carbsConsumed: latest['carbs_consumed'] ?? 0,
          fatConsumed: latest['fat_consumed'] ?? 0,
          proteinTarget: latest['protein_target'] ?? 150,
          carbsTarget: latest['carbs_target'] ?? 200,
          fatTarget: latest['fat_target'] ?? 65,
        );
        state = stats;

        // Sync to Drift
        final db = ref.read(databaseProvider);
        await db.into(db.dailyStats).insertOnConflictUpdate(
          DailyStatsCompanion.insert(
            id: const Value(1),
            date: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
            calorieBudget: stats.calorieBudget,
            caloriesConsumed: stats.caloriesConsumed,
            proteinTarget: stats.proteinTarget,
            proteinConsumed: stats.proteinConsumed,
            carbsTarget: stats.carbsTarget,
            carbsConsumed: stats.carbsConsumed,
            fatTarget: stats.fatTarget,
            fatConsumed: stats.fatConsumed,
          ),
        );
      }
    } catch (_) {
      // Fallback
      final db = ref.read(databaseProvider);
      final local = await db.getStatsForDate(DateTime.now());
      if (local != null) {
        state = models.DailyStats(
          calorieBudget: local.calorieBudget,
          caloriesConsumed: local.caloriesConsumed,
          proteinTarget: local.proteinTarget,
          proteinConsumed: local.proteinConsumed,
          carbsTarget: local.carbsTarget,
          carbsConsumed: local.carbsConsumed,
          fatTarget: local.fatTarget,
          fatConsumed: local.fatConsumed,
        );
      }
    }
  }

  void logFood({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    String name = "Food Item",
  }) {
    final newState = state.copyWith(
      caloriesConsumed: state.caloriesConsumed + calories,
      proteinConsumed: state.proteinConsumed + protein,
      carbsConsumed: state.carbsConsumed + carbs,
      fatConsumed: state.fatConsumed + fat,
    );
    state = newState;

    // Cache locally
    final db = ref.read(databaseProvider);
    db.insertFoodLog(
      FoodLogsCompanion.insert(
        mealName: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      ),
    );

    // Note: The backend /food/analyze endpoints now automatically
    // update DailyStats on the server. No need to post /stats/log here.
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, models.DailyStats>(() {
  return DashboardNotifier();
});

final streakProvider = FutureProvider<int>((ref) async {
  try {
    final response = await ApiClient.instance.get('stats/streak');
    if (response.statusCode == 200) {
      return response.data['streak'] as int;
    }
  } catch (e) {
    // Ignore error and fall through
  }
  return 0;
});
