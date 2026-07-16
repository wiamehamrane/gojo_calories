import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/meal_share_data.dart';

/// Shareable meal card matching the in-app Nutrition screen (white UI).
class MealShareCard extends StatelessWidget {
  static const double width = 390;

  final MealShareData data;

  const MealShareCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ingredients = data.ingredients
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(8)
        .toList();

    return Container(
      width: width,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Meal photo (same hero feel as Nutrition screen)
          SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MealPhoto(bytes: data.imageBytes),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // White content — mirrors food_detail_screen layout
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                if (data.authorName != null &&
                    data.authorName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'by ${data.authorName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Calories card — black flame, black value
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.flame,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Calories',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                          Text(
                            '${data.calories}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Macro row — light grey tiles, colored icons, black amounts
                Row(
                  children: [
                    _MacroTile(
                      label: 'Protein',
                      value: '${data.protein}g',
                      icon: LucideIcons.beef,
                      color: AppColors.protein,
                    ),
                    const SizedBox(width: 10),
                    _MacroTile(
                      label: 'Carbs',
                      value: '${data.carbs}g',
                      icon: LucideIcons.wheat,
                      color: AppColors.carbs,
                    ),
                    const SizedBox(width: 10),
                    _MacroTile(
                      label: 'Fats',
                      value: '${data.fat}g',
                      icon: LucideIcons.droplets,
                      color: AppColors.fats,
                    ),
                  ],
                ),

                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final item in ingredients)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              LucideIcons.check,
                              size: 14,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Brand footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/app_icon.png',
                    width: 18,
                    height: 18,
                    errorBuilder: (_, _, _) => const Icon(
                      LucideIcons.sparkles,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'gojocalories',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealPhoto extends StatelessWidget {
  final Uint8List? bytes;

  const _MealPhoto({required this.bytes});

  @override
  Widget build(BuildContext context) {
    if (bytes != null && bytes!.isNotEmpty) {
      return Image.memory(
        bytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _PhotoFallback(),
      );
    }
    return const _PhotoFallback();
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/avocado.svg',
              width: 56,
              height: 56,
            ),
            const SizedBox(height: 10),
            const Text(
              'No photo',
              style: TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matches [food_detail_screen] `_MacroTile`: light grey card, colored icon, black value.
class _MacroTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MacroTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
