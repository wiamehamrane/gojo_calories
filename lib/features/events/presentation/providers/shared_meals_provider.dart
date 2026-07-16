import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/shared_meals_repository.dart';
import '../../domain/models/shared_meal.dart';

final sharedMealsRepositoryProvider =
    Provider<SharedMealsRepository>((ref) => SharedMealsRepository());

class SharedMealsNotifier extends Notifier<AsyncValue<List<SharedMeal>>> {
  @override
  AsyncValue<List<SharedMeal>> build() {
    fetchMeals();
    return const AsyncValue.loading();
  }

  Future<void> fetchMeals() async {
    try {
      final data =
          await ref.read(sharedMealsRepositoryProvider).getSharedMeals();
      state = AsyncValue.data(
        data
            .map((e) => SharedMeal.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SharedMeal> shareMeal({
    required String name,
    required List<String> ingredients,
    required String instructions,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required File imageFile,
  }) async {
    final data = await ref.read(sharedMealsRepositoryProvider).shareMeal(
          name: name,
          ingredients: ingredients,
          instructions: instructions,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          imageFile: imageFile,
        );
    final meal = SharedMeal.fromJson(data);
    final current = state.value ?? [];
    state = AsyncValue.data([meal, ...current]);
    return meal;
  }

  Future<void> deleteMeal(String mealId) async {
    await ref.read(sharedMealsRepositoryProvider).deleteMeal(mealId);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((m) => m.id != mealId).toList());
  }
}

final sharedMealsProvider =
    NotifierProvider<SharedMealsNotifier, AsyncValue<List<SharedMeal>>>(
  SharedMealsNotifier.new,
);
