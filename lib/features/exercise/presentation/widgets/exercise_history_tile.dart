import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/widgets/cached_food_image.dart';

IconData exerciseIconForName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('run') ||
      lower.contains('course') ||
      lower.contains('jog')) {
    return LucideIcons.footprints;
  }
  if (lower.contains('weight') ||
      lower.contains('lifting') ||
      lower.contains('musculation') ||
      lower.contains('press') ||
      lower.contains('squat') ||
      lower.contains('deadlift')) {
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
    final imageUrl = exercise['image_url']?.toString();
    final setsSummary = exercise['sets_summary']?.toString();
    final hasPhoto = imageUrl != null && imageUrl.isNotEmpty;
    final dateLabel = showTimeOnly
        ? formatExerciseTime(exercise['date']?.toString(), lang)
        : formatExerciseDate(exercise['date']?.toString(), lang);
    final durationLabel = Translations.t(lang, 'exercise_duration_mins')
        .replaceAll('{n}', duration.toString());
    final metaLine = [
      if (dateLabel.isNotEmpty) dateLabel,
      durationLabel,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
        boxShadow: AppShadows.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -24,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryDark.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Row(
                children: [
                  _ExerciseThumb(
                    imageUrl: hasPhoto ? imageUrl : null,
                    name: name,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (setsSummary != null && setsSummary.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            setsSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ] else if (metaLine.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            metaLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Chip(
                              icon: LucideIcons.flame,
                              label: '-$calories kcal',
                              foreground: AppColors.primaryDark,
                              background:
                                  AppColors.primaryDark.withValues(alpha: 0.14),
                            ),
                            if (setsSummary != null &&
                                setsSummary.isNotEmpty &&
                                metaLine.isNotEmpty)
                              _Chip(
                                icon: LucideIcons.clock,
                                label: metaLine,
                                foreground: const Color(0xFF34D399),
                                background: const Color(0xFF34D399)
                                    .withValues(alpha: 0.14),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: AppColors.inactive,
                      ),
                      onPressed: onDelete,
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.textSecondary,
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

class _ExerciseThumb extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const _ExerciseThumb({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.35),
            AppColors.primaryLight,
          ],
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedFoodImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: 62,
                height: 62,
                memCacheWidth: 186,
              )
            : ColoredBox(
                color: AppColors.surface,
                child: Icon(
                  exerciseIconForName(name),
                  size: 26,
                  color: AppColors.primaryDark,
                ),
              ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  const _Chip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
