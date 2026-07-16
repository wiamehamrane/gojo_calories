import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../../domain/models/shared_meal.dart';

/// Card used in the horizontal "Shared meals" row on the Events page.
class SharedMealCard extends StatelessWidget {
  final SharedMeal meal;

  const SharedMealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showSharedMealSheet(context, meal);
      },
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 108,
              width: double.infinity,
              child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                  ? CachedFoodImage(
                      imageUrl: meal.imageUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          const ColoredBox(color: Color(0xFFF2F2F7)),
                      errorWidget: _imageFallback(),
                    )
                  : _imageFallback(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'by ${meal.authorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MacroChip(label: '${meal.calories} kcal'),
                      const SizedBox(width: 6),
                      _MacroChip(label: '${meal.protein}g P'),
                    ],
                  ),
                ],
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
        child: Icon(LucideIcons.utensils, size: 30, color: AppColors.primaryDark),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;

  const _MacroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Full meal details: photo, macros, ingredients, and how to cook it.
void showSharedMealSheet(BuildContext context, SharedMeal meal) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            if (meal.imageUrl != null && meal.imageUrl!.isNotEmpty)
              SizedBox(
                height: 240,
                child: CachedFoodImage(
                  imageUrl: meal.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: const ColoredBox(color: Color(0xFFF2F2F7)),
                  errorWidget: Container(
                    color: AppColors.primaryLight,
                    child: const Center(
                      child: Icon(LucideIcons.utensils,
                          size: 42, color: AppColors.primaryDark),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shared by ${meal.authorName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _MacroStat(value: '${meal.calories}', label: 'kcal'),
                      _MacroStat(value: '${meal.protein}g', label: 'Protein'),
                      _MacroStat(value: '${meal.carbs}g', label: 'Carbs'),
                      _MacroStat(value: '${meal.fat}g', label: 'Fats'),
                    ],
                  ),
                  if (meal.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final ingredient in meal.ingredients)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(LucideIcons.check,
                                  size: 14, color: AppColors.primaryDark),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ingredient,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (meal.instructions != null &&
                      meal.instructions!.trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'How to cook it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      meal.instructions!.trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MacroStat extends StatelessWidget {
  final String value;
  final String label;

  const _MacroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
