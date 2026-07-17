import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/shared_meals_repository.dart';
import '../../domain/models/shared_meal.dart';

final sharedMealsRepositoryProvider =
    Provider<SharedMealsRepository>((ref) => SharedMealsRepository());

List<SharedMeal> _parseMeals(List<dynamic> data) {
  return data
      .map((e) => SharedMeal.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

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
      state = AsyncValue.data(_parseMeals(data));
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
    File? imageFile,
    String? sourceImageUrl,
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
          sourceImageUrl: sourceImageUrl,
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
    ref.invalidate(starredSharedMealsProvider);
  }

  void applyStarState(String mealId, bool isStarred) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current
          .map((m) => m.id == mealId ? m.copyWith(isStarred: isStarred) : m)
          .toList(),
    );
  }

  Future<bool> toggleStar(String mealId) async {
    final previous = state.value;
    if (previous != null) {
      state = AsyncValue.data(
        previous
            .map((m) =>
                m.id == mealId ? m.copyWith(isStarred: !m.isStarred) : m)
            .toList(),
      );
    }

    try {
      final isStarred =
          await ref.read(sharedMealsRepositoryProvider).toggleStar(mealId);
      applyStarState(mealId, isStarred);
      ref.invalidate(starredSharedMealsProvider);
      return true;
    } catch (_) {
      if (previous != null) {
        state = AsyncValue.data(previous);
      }
      return false;
    }
  }
}

final sharedMealsProvider =
    NotifierProvider<SharedMealsNotifier, AsyncValue<List<SharedMeal>>>(
  SharedMealsNotifier.new,
);

class StarredSharedMealsNotifier
    extends Notifier<AsyncValue<List<SharedMeal>>> {
  @override
  AsyncValue<List<SharedMeal>> build() {
    fetchStarred();
    return const AsyncValue.loading();
  }

  Future<void> fetchStarred() async {
    try {
      final data =
          await ref.read(sharedMealsRepositoryProvider).getStarredMeals();
      state = AsyncValue.data(_parseMeals(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleStar(String mealId) async {
    final current = state.value;
    if (current == null) return;

    final previous = current;
    // Optimistically remove from starred list when unstarring.
    state = AsyncValue.data(current.where((m) => m.id != mealId).toList());

    try {
      final isStarred =
          await ref.read(sharedMealsRepositoryProvider).toggleStar(mealId);
      if (isStarred) {
        await fetchStarred();
      }
      ref.read(sharedMealsProvider.notifier).applyStarState(mealId, isStarred);
    } catch (_) {
      state = AsyncValue.data(previous);
    }
  }
}

final starredSharedMealsProvider = NotifierProvider<StarredSharedMealsNotifier,
    AsyncValue<List<SharedMeal>>>(StarredSharedMealsNotifier.new);
