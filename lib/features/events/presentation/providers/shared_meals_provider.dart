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

  void applyLikeState(String mealId, {required bool isLiked, required int likesCount}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current
          .map(
            (m) => m.id == mealId
                ? m.copyWith(isLiked: isLiked, likesCount: likesCount)
                : m,
          )
          .toList(),
    );
  }

  void bumpCommentsCount(String mealId, int delta) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current
          .map(
            (m) => m.id == mealId
                ? m.copyWith(
                    commentsCount: (m.commentsCount + delta).clamp(0, 999999),
                  )
                : m,
          )
          .toList(),
    );
  }

  void applyCommentsEnabled(String mealId, bool enabled) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current
          .map(
            (m) =>
                m.id == mealId ? m.copyWith(commentsEnabled: enabled) : m,
          )
          .toList(),
    );
    ref
        .read(starredSharedMealsProvider.notifier)
        .applyCommentsEnabled(mealId, enabled);
  }

  Future<bool> setCommentsEnabled(String mealId, bool enabled) async {
    final previous = state.value;
    applyCommentsEnabled(mealId, enabled);
    try {
      final result = await ref
          .read(sharedMealsRepositoryProvider)
          .setCommentsEnabled(mealId, enabled);
      applyCommentsEnabled(mealId, result);
      return true;
    } catch (_) {
      if (previous != null) state = AsyncValue.data(previous);
      return false;
    }
  }

  Future<bool> deleteComment(String mealId, String commentId) async {
    try {
      await ref
          .read(sharedMealsRepositoryProvider)
          .deleteComment(mealId, commentId);
      bumpCommentsCount(mealId, -1);
      ref.invalidate(mealCommentsProvider(mealId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleLike(String mealId) async {
    final previous = state.value;
    if (previous != null) {
      state = AsyncValue.data(
        previous.map((m) {
          if (m.id != mealId) return m;
          final nextLiked = !m.isLiked;
          return m.copyWith(
            isLiked: nextLiked,
            likesCount: (m.likesCount + (nextLiked ? 1 : -1)).clamp(0, 999999),
          );
        }).toList(),
      );
    }

    try {
      final data =
          await ref.read(sharedMealsRepositoryProvider).toggleLike(mealId);
      applyLikeState(
        mealId,
        isLiked: data['is_liked'] as bool? ?? false,
        likesCount: (data['likes_count'] as num?)?.toInt() ?? 0,
      );
      return true;
    } catch (_) {
      if (previous != null) state = AsyncValue.data(previous);
      return false;
    }
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

  void applyCommentsEnabled(String mealId, bool enabled) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current
          .map(
            (m) =>
                m.id == mealId ? m.copyWith(commentsEnabled: enabled) : m,
          )
          .toList(),
    );
  }
}

final starredSharedMealsProvider = NotifierProvider<StarredSharedMealsNotifier,
    AsyncValue<List<SharedMeal>>>(StarredSharedMealsNotifier.new);

final mealCommentsProvider = FutureProvider.autoDispose
    .family<List<SharedMealComment>, String>((ref, mealId) async {
  final data =
      await ref.read(sharedMealsRepositoryProvider).getComments(mealId);
  return data
      .map((e) =>
          SharedMealComment.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

