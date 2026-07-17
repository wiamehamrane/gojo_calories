import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../../domain/models/shared_meal.dart';
import '../providers/shared_meals_provider.dart';
import '../widgets/shared_meal_card.dart';

final _publicProfileProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    return ref.read(sharedMealsRepositoryProvider).getPublicProfile(userId);
  },
);

class PublicProfileScreen extends ConsumerWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_publicProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            size: 24,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 14)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              AppErrorHandler.message(e),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (profile) {
          final isPublic = profile['is_public'] as bool? ?? false;
          final name = profile['name'] as String? ?? 'Gojo member';
          if (!isPublic) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.surfaceMuted,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This profile is private.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final age = profile['age'];
          final gender = profile['gender'] as String?;
          final meals = (profile['meals'] as List?)
                  ?.map((e) => SharedMeal.fromJson(
                        Map<String, dynamic>.from(e as Map),
                      ))
                  .toList() ??
              const <SharedMeal>[];

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(_publicProfileProvider(userId));
              await ref.read(_publicProfileProvider(userId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (age != null || (gender != null && gender.isNotEmpty)) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (age != null) '$age yrs',
                      if (gender != null && gender.isNotEmpty) gender,
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  meals.isEmpty
                      ? 'Shared meals'
                      : 'Shared meals (${meals.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (meals.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(LucideIcons.utensils,
                            size: 28, color: AppColors.inactive),
                        SizedBox(height: 10),
                        Text(
                          'No meals shared yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final meal in meals)
                    _ProfileMealTile(
                      meal: meal,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        showSharedMealSheet(context, meal);
                      },
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileMealTile extends StatelessWidget {
  final SharedMeal meal;
  final VoidCallback onTap;

  const _ProfileMealTile({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                    ? CachedFoodImage(
                        imageUrl: meal.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 216,
                        placeholder:
                            const ColoredBox(color: Color(0xFFF2F2F7)),
                        errorWidget: _fallback(),
                      )
                    : _fallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${meal.calories} kcal · ${meal.protein}g P · ${meal.carbs}g C · ${meal.fat}g F',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        meal.isLiked ? Icons.favorite : LucideIcons.heart,
                        size: 13,
                        color: meal.isLiked
                            ? const Color(0xFFE11D48)
                            : AppColors.inactive,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${meal.likesCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        LucideIcons.messageCircle,
                        size: 13,
                        color: AppColors.inactive,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${meal.commentsCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.inactive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(LucideIcons.utensils, size: 24, color: AppColors.primaryDark),
      ),
    );
  }
}
