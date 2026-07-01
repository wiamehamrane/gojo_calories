import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

class FoodScanNotifier extends Notifier<AsyncValue<Map<String, dynamic>?>> {
  @override
  AsyncValue<Map<String, dynamic>?> build() => const AsyncValue.data(null);

  Future<Map<String, dynamic>?> analyzeImage(File image, String localDate) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(foodRepositoryProvider);
      final result = await repo.analyzeImage(image, localDate: localDate);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(foodRepositoryProvider);
      final result = await repo.getBarcodeNutrition(barcode);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logBarcodeItem(
    Map<String, dynamic> data, {
    required String localDate,
  }) async {
    await ref.read(foodRepositoryProvider).logBarcodeItem(
          data,
          localDate: localDate,
        );
  }
}

final foodScanProvider =
    NotifierProvider<FoodScanNotifier, AsyncValue<Map<String, dynamic>?>>(
  FoodScanNotifier.new,
);

class FoodLogNotifier extends Notifier<AsyncValue<List<dynamic>>> {
  @override
  AsyncValue<List<dynamic>> build() => const AsyncValue.data([]);

  Future<List<dynamic>> fetchHistory(DateTime date) async {
    state = const AsyncValue.loading();
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final repo = ref.read(foodRepositoryProvider);
      final data = await repo.getHistory(
        date: dateStr,
        tzOffset: date.timeZoneOffset.inMinutes,
      );
      state = AsyncValue.data(data);
      return data;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logFoodItem(Map<String, dynamic> data) async {
    await ref.read(foodRepositoryProvider).logFoodItem(data);
  }
}

final foodLogProvider =
    NotifierProvider<FoodLogNotifier, AsyncValue<List<dynamic>>>(
  FoodLogNotifier.new,
);

class FoodDetailNotifier extends Notifier<AsyncValue<List<dynamic>>> {
  @override
  AsyncValue<List<dynamic>> build() => const AsyncValue.data([]);

  Future<List<dynamic>> fetchIngredients(String name) async {
    state = const AsyncValue.loading();
    try {
      final data = await ref.read(foodRepositoryProvider).getIngredients(name);
      state = AsyncValue.data(data);
      return data;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> saveFood(Map<String, dynamic> data) async {
    await ref.read(foodRepositoryProvider).saveFood(data);
  }
}

final foodDetailProvider =
    NotifierProvider<FoodDetailNotifier, AsyncValue<List<dynamic>>>(
  FoodDetailNotifier.new,
);

class FixResultsNotifier extends Notifier<AsyncValue<Map<String, dynamic>?>> {
  @override
  AsyncValue<Map<String, dynamic>?> build() => const AsyncValue.data(null);

  Future<Map<String, dynamic>> fixFoodLog({
    required String logId,
    required String prompt,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(foodRepositoryProvider).fixFoodLog(
            logId: logId,
            prompt: prompt,
          );
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final fixResultsProvider =
    NotifierProvider<FixResultsNotifier, AsyncValue<Map<String, dynamic>?>>(
  FixResultsNotifier.new,
);

class FoodDatabaseNotifier extends Notifier<AsyncValue<List<dynamic>>> {
  @override
  AsyncValue<List<dynamic>> build() => const AsyncValue.data([]);

  Future<List<dynamic>> search(String query) async {
    state = const AsyncValue.loading();
    try {
      final data = await ref.read(foodRepositoryProvider).searchFood(query);
      state = AsyncValue.data(data);
      return data;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> saveFood(Map<String, dynamic> data) async {
    await ref.read(foodRepositoryProvider).saveFood(data);
  }
}

final foodDatabaseProvider =
    NotifierProvider<FoodDatabaseNotifier, AsyncValue<List<dynamic>>>(
  FoodDatabaseNotifier.new,
);
