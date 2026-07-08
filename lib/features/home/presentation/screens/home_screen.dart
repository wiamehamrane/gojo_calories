import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gojocalories/core/utils/image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../features/stats/presentation/providers/selected_date_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../stats/presentation/providers/dashboard_provider.dart';
import '../../../stats/presentation/providers/history_provider.dart';
import '../../../stats/presentation/providers/weekly_stats_provider.dart';
import '../../../exercise/presentation/providers/exercise_providers.dart';
import '../../../exercise/presentation/widgets/exercise_history_tile.dart';
import 'package:intl/intl.dart';
import '../widgets/swipable_stat_card.dart';
import '../widgets/calorie_ring_inner.dart';
import '../widgets/macro_tile_inner.dart';
import '../widgets/home_day_shimmer.dart';
import '../widgets/weekly_calendar.dart';
import '../widgets/bmi_widget.dart';
import '../widgets/health_connect_card.dart';
import '../../../tasks/presentation/widgets/active_tasks_carousel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, ref),
            Expanded(child: _buildHomeContent(context, ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final statsAsync = ref.watch(dashboardProvider);
    final historyAsync = ref.watch(historyProvider(selectedDate));
    final exercisesAsync = ref.watch(dailyExercisesProvider(selectedDate));
    final weeklyAsync = ref.watch(weeklyStatsProvider);
    final weeklyData = weeklyAsync.value;

    final isLoadingDay = statsAsync.isLoading ||
        historyAsync.isLoading ||
        exercisesAsync.isLoading;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const WeeklyCalendar(),
          const SizedBox(height: 16),
          const HealthConnectCard(),
          const SizedBox(height: 16),
          const ActiveTasksCarousel(),
          const SizedBox(height: AppSpacing.cardGap),
          if (isLoadingDay)
            const HomeDayShimmer()
          else ...[
            statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: SizedBox(
                      height: 160,
                      child: SwipableStatCard(
                        title: Translations.t(lang, 'calories_label'),
                        themeColor: AppColors.primaryMid,
                        chartData: weeklyData?.calorieSpots,
                        extraPage: const BmiWidget(),
                        primaryView: CalorieRingInner(stats: stats, lang: lang),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: SizedBox(
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SwipableStatCard(
                              title: Translations.t(lang, 'macro_protein'),
                              themeColor: AppColors.protein,
                              chartData: weeklyData?.proteinSpots,
                              primaryView: MacroTileInner(
                                macroName:
                                    Translations.t(lang, 'macro_protein'),
                                lang: lang,
                                total: stats.proteinTarget,
                                consumed: stats.proteinConsumed,
                                macroColor: AppColors.protein,
                                macroIcon: LucideIcons.beef,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.macroTileGap),
                          Expanded(
                            child: SwipableStatCard(
                              title: Translations.t(lang, 'macro_carbs'),
                              themeColor: AppColors.carbs,
                              chartData: weeklyData?.carbsSpots,
                              primaryView: MacroTileInner(
                                macroName: Translations.t(lang, 'macro_carbs'),
                                lang: lang,
                                total: stats.carbsTarget,
                                consumed: stats.carbsConsumed,
                                macroColor: AppColors.carbs,
                                macroIcon: LucideIcons.wheat,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.macroTileGap),
                          Expanded(
                            child: SwipableStatCard(
                              title: Translations.t(lang, 'macro_fats'),
                              themeColor: AppColors.fats,
                              chartData: weeklyData?.fatSpots,
                              primaryView: MacroTileInner(
                                macroName: Translations.t(lang, 'macro_fats'),
                                lang: lang,
                                total: stats.fatTarget,
                                consumed: stats.fatConsumed,
                                macroColor: AppColors.fats,
                                macroIcon: LucideIcons.droplets,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const HomeDayShimmer(),
              error: (_, _) => _buildDayError(lang),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Text(
                Translations.t(lang, 'recently_uploaded'),
                style:
                    AppTextStyles.sectionHeader.copyWith(color: Colors.black),
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentMeals(context, ref, lang, historyAsync),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Text(
                Translations.t(lang, 'daily_workouts'),
                style:
                    AppTextStyles.sectionHeader.copyWith(color: Colors.black),
              ),
            ),
            const SizedBox(height: 12),
            _buildDailyExercises(context, ref, lang, exercisesAsync, selectedDate),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDayError(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          Translations.t(lang, 'error_generic'),
          style: const TextStyle(color: AppColors.danger),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final streakValue = streakAsync.maybeWhen(
      data: (val) => val.toString(),
      orElse: () => '0',
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              //const Text('🥑', style: TextStyle(fontSize: 26)),
              Image.asset(ImageAsset.logoHeader, width: 35, height: 35),
              const SizedBox(width: 6),
              const Text(
                'GojoCalories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/flame_gradient.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  streakValue,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyExercises(
    BuildContext context,
    WidgetRef ref,
    String lang,
    AsyncValue<List<Map<String, dynamic>>> exercisesAsync,
    DateTime selectedDate,
  ) {
    final isToday = isSameCalendarDay(selectedDate, DateTime.now());

    return exercisesAsync.when(
      data: (exercises) {
        if (exercises.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                Translations.t(
                  lang,
                  isToday ? 'no_exercises_today' : 'no_exercises_logged',
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.inactive,
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            children: exercises
                .map(
                  (exercise) => ExerciseHistoryTile(
                    exercise: exercise,
                    lang: lang,
                    showTimeOnly: true,
                  ),
                )
                .toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            Translations.t(lang, 'error_generic'),
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMeals(
    BuildContext context,
    WidgetRef ref,
    String lang,
    AsyncValue<List<dynamic>> historyAsync,
  ) {
    return historyAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.utensilsCrossed,
                    size: 48,
                    color: AppColors.inactive,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Translations.t(lang, 'no_food_logged'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.inactive,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: List.generate(
            logs.length,
            (i) {
              final log = logs[i] as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => context.push('/food-detail', extra: log),
                child: _AnimatedMealCard(log: logs[i], index: i, lang: lang),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Center(
        child: Text(
          Translations.t(lang, 'failed_load_history'),
          style: const TextStyle(color: AppColors.danger),
        ),
      ),
    );
  }
}

// ─── Animated Meal Card ────────────────────────────────────────────────────

class _AnimatedMealCard extends StatefulWidget {
  final dynamic log;
  final int index;
  final String lang;
  const _AnimatedMealCard({
    required this.log,
    required this.index,
    required this.lang,
  });

  @override
  State<_AnimatedMealCard> createState() => _AnimatedMealCardState();
}

class _AnimatedMealCardState extends State<_AnimatedMealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 320 + widget.index * 50),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final imageUrl = log['image_url'] as String?;

    String mealName = (log['meal_name'] ?? 'Unknown Meal') as String;
    if (widget.lang == 'ar' || widget.lang == 'Darija') {
      if (log['name_ar'] != null) mealName = log['name_ar'] as String;
    } else if (widget.lang == 'fr') {
      if (log['name_fr'] != null) mealName = log['name_fr'] as String;
    } else if (log['name_en'] != null) {
      mealName = log['name_en'] as String;
    }

    final calories = log['calories']?.toString() ?? '0';
    final protein = log['protein']?.toString() ?? '';
    final carbs = log['carbs']?.toString() ?? '';
    final fat = log['fat']?.toString() ?? '';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: CachedFoodImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: 72,
                  height: 72,
                  memCacheWidth: 216,
                  memCacheHeight: 216,
                  errorWidget: const _FoodPlaceholder(),
                ),
                ),

              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealName,
                        style: AppTextStyles.bodyBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(LucideIcons.flame, size: 13, color: AppColors.fire),
                          Text(
                            ' $calories kcal',
                            style: AppTextStyles.bodyRegular,
                          ),
                        ],
                      ),
                      if (protein.isNotEmpty || carbs.isNotEmpty || fat.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (protein.isNotEmpty)
                              _MacroChip(label: '${protein}g P', color: AppColors.protein),
                            if (carbs.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _MacroChip(label: '${carbs}g C', color: AppColors.carbs),
                            ],
                            if (fat.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _MacroChip(label: '${fat}g F', color: AppColors.fats),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  _getRelativeDate(log['created_at']?.toString(), widget.lang),
                  style: const TextStyle(fontSize: 11, color: AppColors.inactive),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRelativeDate(String? isoString, String lang) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final logDate = DateTime(date.year, date.month, date.day);
      if (logDate == today) return DateFormat('h:mm a').format(date);
      if (logDate == yesterday) return 'Yesterday';
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return '';
    }
  }
}

class _FoodPlaceholder extends StatelessWidget {
  const _FoodPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Center(
        child: Icon(LucideIcons.utensils, size: 24, color: AppColors.inactive),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
