import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/database_provider.dart';

final historyProvider = FutureProvider.family<List<dynamic>, DateTime>((ref, date) async {
  final dateStr =
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  try {
    final res = await ApiClient.instance.get(
      'stats/history',
      queryParameters: {'date': dateStr},
    );
    final apiData = res.data ?? [];
    return apiData;
  } catch (e) {
    // Fallback to Drift
    final db = ref.read(databaseProvider);
    final localLogs = await db.getAllFoodLogs();
    
    // Filter by same day
    return localLogs
        .where((log) => 
            log.createdAt.year == date.year &&
            log.createdAt.month == date.month &&
            log.createdAt.day == date.day)
        .map(
          (log) => {
            'meal_name': log.mealName,
            'name_en': log.nameEn,
            'name_fr': log.nameFr,
            'name_ar': log.nameAr,
            'calories': log.calories,
            'protein': log.protein,
            'carbs': log.carbs,
            'fat': log.fat,
            'image_url': log.imageUrl,
            'ingredients': log.ingredients != null ? jsonDecode(log.ingredients!) : null,
            'created_at': log.createdAt.toIso8601String(),
          },
        )
        .toList();
  }
});
