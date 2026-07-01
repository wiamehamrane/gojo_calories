import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/di/repository_providers.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/database.dart';
import '../../data/models/daily_stats.dart' as models;
import 'selected_date_provider.dart';

class DashboardNotifier extends Notifier<models.DailyStats> {
  @override
  models.DailyStats build() {
    final date = ref.watch(selectedDateProvider);
    _loadData(date);
    return models.DailyStats(
      calorieBudget: 0,
      caloriesConsumed: 0,
      proteinConsumed: 0,
      carbsConsumed: 0,
      fatConsumed: 0,
      proteinTarget: 0,
      carbsTarget: 0,
      fatTarget: 0,
    );
  }

  Future<void> _loadData(DateTime date) async {
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final tzOffset = date.timeZoneOffset.inMinutes;
    try {
      final data = await ref.read(statsRepositoryProvider).getDailyStats(
            date: dateStr,
            tzOffset: tzOffset,
          );
      if (data.isNotEmpty) {
        final latest = data.first as Map<String, dynamic>;
        final stats = models.DailyStats(
          calorieBudget: latest['calorie_budget'] ?? 0,
          caloriesConsumed: latest['calories_consumed'] ?? 0,
          proteinConsumed: latest['protein_consumed'] ?? 0,
          carbsConsumed: latest['carbs_consumed'] ?? 0,
          fatConsumed: latest['fat_consumed'] ?? 0,
          proteinTarget: latest['protein_target'] ?? 0,
          carbsTarget: latest['carbs_target'] ?? 0,
          fatTarget: latest['fat_target'] ?? 0,
        );
        state = stats;

        final db = ref.read(databaseProvider);
        await db.into(db.dailyStats).insertOnConflictUpdate(
              DailyStatsCompanion.insert(
                id: const Value(1),
                date: DateTime(date.year, date.month, date.day),
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
      final db = ref.read(databaseProvider);
      final local = await db.getStatsForDate(date);
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
    String? nameEn,
    String? nameFr,
    String? nameAr,
    String? imageUrl,
    List<dynamic>? ingredients,
  }) {
    final newState = state.copyWith(
      caloriesConsumed: state.caloriesConsumed + calories,
      proteinConsumed: state.proteinConsumed + protein,
      carbsConsumed: state.carbsConsumed + carbs,
      fatConsumed: state.fatConsumed + fat,
    );
    state = newState;

    final db = ref.read(databaseProvider);
    db.insertFoodLog(
      FoodLogsCompanion.insert(
        mealName: name,
        nameEn: Value(nameEn),
        nameFr: Value(nameFr),
        nameAr: Value(nameAr),
        imageUrl: Value(imageUrl),
        ingredients: Value(ingredients != null ? jsonEncode(ingredients) : null),
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      ),
    );
  }
}

final dashboardProvider =
    NotifierProvider<DashboardNotifier, models.DailyStats>(
  DashboardNotifier.new,
);

final streakProvider = FutureProvider<int>((ref) async {
  try {
    final tzOffset = DateTime.now().timeZoneOffset.inMinutes;
    return await ref.read(statsRepositoryProvider).getStreak(tzOffset: tzOffset);
  } catch (_) {
    return 0;
  }
});
