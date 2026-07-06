import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../stats/presentation/providers/dashboard_provider.dart';
import '../../../stats/presentation/providers/selected_date_provider.dart';
import '../providers/exercise_providers.dart';
import '../widgets/exercise_history_tile.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatSelectedDate(DateTime date, String lang) {
  final locale = lang == 'fr' ? 'fr_FR' : (lang == 'ar' ? 'ar' : 'en_US');
  return DateFormat.MMMd(locale).format(date);
}

class LogExerciseScreen extends ConsumerStatefulWidget {
  const LogExerciseScreen({super.key});

  @override
  ConsumerState<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends ConsumerState<LogExerciseScreen> {
  Future<void> _refreshExercises() async {
    final date = ref.read(selectedDateProvider);
    ref.invalidate(dailyExercisesProvider(date));
    await ref.read(dailyExercisesProvider(date).future);
  }

  Future<void> _deleteExercise(
    BuildContext context,
    String lang,
    Map<String, dynamic> exercise,
  ) async {
    final id = exercise['id']?.toString();
    if (id == null) return;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: Translations.t(lang, 'delete_exercise'),
      message: Translations.t(lang, 'delete_exercise_confirm'),
      cancelLabel: Translations.t(lang, 'keep'),
      confirmLabel: Translations.t(lang, 'delete_permanently'),
      destructive: true,
    );
    if (!confirmed) return;
    if (!context.mounted) return;

    try {
      await ref.read(exerciseRepositoryProvider).deleteExercise(id);
      final date = ref.read(selectedDateProvider);
      ref.invalidate(dailyExercisesProvider(date));
      ref.invalidate(exercisesProvider);
      ref.invalidate(dashboardProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'exercise_deleted')),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'error_generic')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    String t(String k) => Translations.t(lang, k);
    final exercisesAsync = ref.watch(dailyExercisesProvider(selectedDate));
    final isToday = _isSameDay(selectedDate, DateTime.now());
    final historyTitle = isToday
        ? t('todays_workouts')
        : t('workouts_on_date')
            .replaceAll('{date}', _formatSelectedDate(selectedDate, lang));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('log_exercise'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshExercises,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(t('log_exercise'), style: AppTextStyles.screenTitle),
              const SizedBox(height: 20),
              _ExerciseOptionCard(
                icon: LucideIcons.footprints,
                name: t('run'),
                desc: 'Running, jogging, sprinting, etc.',
                onTap: () async {
                  await context.push('/run_intensity');
                  if (mounted) {
                    ref.invalidate(dailyExercisesProvider(selectedDate));
                  }
                },
              ),
              const SizedBox(height: 10),
              _ExerciseOptionCard(
                icon: LucideIcons.dumbbell,
                name: t('weight_lifting'),
                desc: 'Machines, free weights, etc.',
                onTap: () async {
                  await context.push('/weight_lifting');
                  if (mounted) {
                    ref.invalidate(dailyExercisesProvider(selectedDate));
                  }
                },
              ),
              const SizedBox(height: 10),
              _ExerciseOptionCard(
                icon: LucideIcons.pencil,
                name: t('describe'),
                desc: t('describe_hint'),
                onTap: () async {
                  await context.push('/describe_exercise');
                  if (mounted) {
                    ref.invalidate(dailyExercisesProvider(selectedDate));
                  }
                },
              ),
              const SizedBox(height: 10),
              _ExerciseOptionCard(
                icon: LucideIcons.flame,
                name: t('manual'),
                desc: t('calories_burned'),
                onTap: () async {
                  await context.push('/manual_exercise');
                  if (mounted) {
                    ref.invalidate(dailyExercisesProvider(selectedDate));
                  }
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Icon(
                    LucideIcons.history,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(historyTitle, style: AppTextStyles.sectionHeader),
                ],
              ),
              const SizedBox(height: 14),
              exercisesAsync.when(
                data: (exercises) {
                  if (exercises.isEmpty) {
                    return _EmptyExerciseHistory(
                      message: isToday
                          ? t('no_exercises_today')
                          : t('no_exercises_logged'),
                    );
                  }
                  return Column(
                    children: exercises
                        .map(
                          (exercise) => ExerciseHistoryTile(
                            exercise: exercise,
                            lang: lang,
                            showTimeOnly: true,
                            onDelete: () =>
                                _deleteExercise(context, lang, exercise),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (_, _) => _EmptyExerciseHistory(
                  message: Translations.t(lang, 'error_generic'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyExerciseHistory extends StatelessWidget {
  final String message;

  const _EmptyExerciseHistory({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.activity,
            size: 40,
            color: AppColors.inactive,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.inactive,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseOptionCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String desc;
  final VoidCallback onTap;

  const _ExerciseOptionCard({
    required this.icon,
    required this.name,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
