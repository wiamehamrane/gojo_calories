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
          icon: Icon(
            LucideIcons.chevronLeft,
            size: 24,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: Text(
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
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (profile) {
          final isPublic = profile['is_public'] as bool? ?? false;
          final name = profile['name'] as String? ?? 'Gojo member';
          final avatarUrl = profile['avatar_url'] as String?;
          if (!isPublic) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 36),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
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
                  child: _ProfileAvatar(
                    name: name,
                    avatarUrl: avatarUrl,
                    radius: 42,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                    style: TextStyle(
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
                  style: TextStyle(
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
                    child: Column(
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

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;

  const _ProfileAvatar({
    required this.name,
    required this.avatarUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;
    final size = radius * 2;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: ClipOval(
        child: hasPhoto
            ? CachedFoodImage(
                imageUrl: avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                placeholder: _initials(),
                errorWidget: _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
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
                            ColoredBox(color: AppColors.background),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${meal.calories} kcal · ${meal.protein}g P · ${meal.carbs}g C · ${meal.fat}g F',
                    style: TextStyle(
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
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        LucideIcons.messageCircle,
                        size: 13,
                        color: AppColors.inactive,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${meal.commentsCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
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
      child: Center(
        child: Icon(LucideIcons.utensils, size: 24, color: AppColors.primaryDark),
      ),
    );
  }
}
