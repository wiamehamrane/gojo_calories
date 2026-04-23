import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/database_provider.dart';

final historyProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiClient.instance.get('stats/history');
    final apiData = res.data ?? [];
    return apiData;
  } catch (e) {
    // Fallback to Drift
    final db = ref.read(databaseProvider);
    final localLogs = await db.getAllFoodLogs();
    return localLogs
        .map(
          (log) => {
            'meal_name': log.mealName,
            'calories': log.calories,
            'protein': log.protein,
            'carbs': log.carbs,
            'fat': log.fat,
            'created_at': log.createdAt.toIso8601String(),
          },
        )
        .toList();
  }
});
