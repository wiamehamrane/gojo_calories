import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../../domain/models/shared_meal.dart';
import '../providers/shared_meals_provider.dart';
import '../widgets/shared_meal_card.dart';

/// Profile screen listing meals the current user has starred.
class StarredMealsScreen extends ConsumerWidget {
  const StarredMealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final starredAsync = ref.watch(starredSharedMealsProvider);

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
        title: Text(
          t('starred_meals'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(starredSharedMealsProvider.notifier).fetchStarred(),
        child: starredAsync.when(
          loading: () =>
              const Center(child: CupertinoActivityIndicator(radius: 14)),
          error: (e, _) => _MessageState(
            icon: LucideIcons.wifiOff,
            title: t('starred_meals_load_error'),
            message: AppErrorHandler.message(e),
            actionLabel: t('retry'),
            onAction: () =>
                ref.read(starredSharedMealsProvider.notifier).fetchStarred(),
          ),
          data: (meals) {
            if (meals.isEmpty) {
              return _MessageState(
                icon: LucideIcons.star,
                title: t('starred_meals_empty_title'),
                message: t('starred_meals_empty_message'),
              );
            }
            return ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                8,
                AppSpacing.screenPadding,
                40,
              ),
              itemCount: meals.length,
              itemBuilder: (context, index) =>
                  _StarredMealTile(meal: meals[index]),
            );
          },
        ),
      ),
    );
  }
}

class _StarredMealTile extends ConsumerWidget {
  final SharedMeal meal;

  const _StarredMealTile({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showSharedMealSheet(context, meal);
      },
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
                        errorWidget: _imageFallback(),
                      )
                    : _imageFallback(),
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
                  const SizedBox(height: 4),
                  Text(
                    'by ${meal.authorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref
                    .read(starredSharedMealsProvider.notifier)
                    .toggleStar(meal.id);
              },
              icon: const Icon(
                Icons.star_rounded,
                size: 22,
                color: Color(0xFFF5A623),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(LucideIcons.utensils, size: 24, color: AppColors.primaryDark),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        Icon(icon, size: 40, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
