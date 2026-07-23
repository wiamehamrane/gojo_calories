import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/di/repository_providers.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/database.dart';
import '../../data/models/daily_stats.dart' as models;
import '../../../exercise/presentation/providers/exercise_providers.dart';
import 'calendar_progress_provider.dart';
import 'selected_date_provider.dart';

class DashboardNotifier extends AsyncNotifier<models.DailyStats> {
  @override
  Future<models.DailyStats> build() async {
    final date = ref.watch(selectedDateProvider);
    return _fetchStats(date);
  }

  Future<models.DailyStats> _fetchStats(DateTime date) async {
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
        return stats;
      }
    } catch (_) {
      final db = ref.read(databaseProvider);
      final local = await db.getStatsForDate(date);
      if (local != null) {
        return models.DailyStats(
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

    return models.DailyStats(
      calorieBudget: 0,
      caloriesConsumed: 0,
      proteinTarget: 0,
      carbsTarget: 0,
      fatTarget: 0,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> logExercise({
    required String name,
    required int durationMinutes,
    required int caloriesBurned,
    String? imageUrl,
    String? setsSummary,
  }) async {
    final date = ref.read(selectedDateProvider);
    final localDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await ref.read(exerciseRepositoryProvider).logExercise(
          name: name,
          durationMinutes: durationMinutes,
          caloriesBurned: caloriesBurned,
          localDate: localDate,
          imageUrl: imageUrl,
          setsSummary: setsSummary,
        );

    ref.invalidate(dailyExercisesProvider(date));
    ref.invalidate(exercisesProvider);
    ref.invalidate(calendarProgressProvider);
    ref.invalidateSelf();
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
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          caloriesConsumed: current.caloriesConsumed + calories,
          proteinConsumed: current.proteinConsumed + protein,
          carbsConsumed: current.carbsConsumed + carbs,
          fatConsumed: current.fatConsumed + fat,
        ),
      );
    }

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
    ref.invalidate(calendarProgressProvider);
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, models.DailyStats>(
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

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
