import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/tasks_provider.dart';

/// "Today's Tasks" card: two rows of dots that fill up as today's tasks get
/// completed, with the completion percentage on the right. Always expanded.
class DayProgressDots extends ConsumerWidget {
  static const int _dotsPerRow = 12;
  static const int _totalDots = _dotsPerRow * 2;

  const DayProgressDots({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final progress = ref.watch(todayProgressProvider);
    final ratio = progress.ratio.clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final filledDots = (ratio * _totalDots).round().clamp(0, _totalDots);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Translations.t(lang, 'tasks_day'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final dotSize =
                  ((constraints.maxWidth - (_dotsPerRow - 1) * 8) /
                          _dotsPerRow)
                      .clamp(8.0, 18.0);
              return Column(
                children: [
                  _dotRow(0, filledDots, dotSize),
                  const SizedBox(height: 10),
                  _dotRow(1, filledDots, dotSize),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dotRow(int row, int filledDots, double dotSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_dotsPerRow, (i) {
        final index = row * _dotsPerRow + i;
        final filled = index < filledDots;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : AppColors.ringTrack,
          ),
        );
      }),
    );
  }
}
