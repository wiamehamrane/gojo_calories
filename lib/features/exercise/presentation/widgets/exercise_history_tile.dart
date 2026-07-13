import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/locale_provider.dart';

IconData exerciseIconForName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('run') ||
      lower.contains('course') ||
      lower.contains('jog')) {
    return LucideIcons.footprints;
  }
  if (lower.contains('weight') ||
      lower.contains('lifting') ||
      lower.contains('musculation')) {
    return LucideIcons.dumbbell;
  }
  return LucideIcons.flame;
}

String formatExerciseTime(String? isoDate, String lang) {
  if (isoDate == null || isoDate.isEmpty) return '';
  final parsed = DateTime.tryParse(isoDate.replaceFirst('Z', ''));
  if (parsed == null) return '';
  return DateFormat.jm(toIntlLocale(lang)).format(parsed.toLocal());
}

String formatExerciseDate(String? isoDate, String lang) {
  if (isoDate == null || isoDate.isEmpty) return '';
  final parsed = DateTime.tryParse(isoDate.replaceFirst('Z', ''));
  if (parsed == null) return '';

  final local = parsed.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final exerciseDay = DateTime(local.year, local.month, local.day);

  if (exerciseDay == today) {
    return Translations.t(lang, 'today');
  }
  if (exerciseDay == today.subtract(const Duration(days: 1))) {
    return Translations.t(lang, 'yesterday');
  }

  return DateFormat.MMMd(toIntlLocale(lang)).format(local);
}

class ExerciseHistoryTile extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final String lang;
  final VoidCallback? onDelete;
  final bool showTimeOnly;

  const ExerciseHistoryTile({
    super.key,
    required this.exercise,
    required this.lang,
    this.onDelete,
    this.showTimeOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = exercise['name']?.toString() ?? 'Exercise';
    final duration = exercise['duration_minutes'] ?? 0;
    final calories = exercise['calories_burned'] ?? 0;
    final dateLabel = showTimeOnly
        ? formatExerciseTime(exercise['date']?.toString(), lang)
        : formatExerciseDate(exercise['date']?.toString(), lang);
    final durationLabel = Translations.t(lang, 'exercise_duration_mins')
        .replaceAll('{n}', duration.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                exerciseIconForName(name),
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [dateLabel, durationLabel]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-$calories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: AppColors.inactive,
                ),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
