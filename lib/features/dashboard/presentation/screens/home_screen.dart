import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/selected_date_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/weekly_stats_provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../widgets/swipable_stat_card.dart';
import '../widgets/calorie_ring_inner.dart';
import '../widgets/macro_tile_inner.dart';
import '../widgets/weekly_calendar.dart';
import '../widgets/bmi_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    final lang = ref.watch(localeProvider);
    final weeklyAsync = ref.watch(weeklyStatsProvider);

    // Extract chart data if available
    final weeklyData = weeklyAsync.value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8E8EC), AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, ref),
                const SizedBox(height: 4),
                const WeeklyCalendar(),
                const SizedBox(height: 20),
                // ─── Calorie Card (3 pages: Stats | Chart | BMI) ─────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: SizedBox(
                    height: 160,
                    child: SwipableStatCard(
                      title: 'Calories',
                      themeColor: AppColors.primaryMid,
                      chartData: weeklyData?.calorieSpots,
                      extraPage: const BmiWidget(),
                      primaryView: CalorieRingInner(stats: stats, lang: lang),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                // ─── Macro Tiles Row ──────────────────────────────────────
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
                            title: 'Protein',
                            themeColor: AppColors.protein,
                            chartData: weeklyData?.proteinSpots,
                            primaryView: MacroTileInner(
                              macroName: Translations.t(lang, 'macro_protein'),
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
                            title: 'Carbs',
                            themeColor: AppColors.carbs,
                            chartData: weeklyData?.carbsSpots,
                            primaryView: MacroTileInner(
                              macroName: Translations.t(lang, 'macro_carbs'),
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
                            title: 'Fats',
                            themeColor: AppColors.fats,
                            chartData: weeklyData?.fatSpots,
                            primaryView: MacroTileInner(
                              macroName: Translations.t(lang, 'macro_fats'),
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
                const SizedBox(height: 28),
                // ─── Section Header ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Translations.t(lang, 'recently_uploaded'),
                        style: AppTextStyles.sectionHeader
                            .copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentMeals(context, ref, lang),
                const SizedBox(height: 100),
              ],
            ),
          ),
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
              const Text('🥑', style: TextStyle(fontSize: 26)),
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

  Widget _buildRecentMeals(BuildContext context, WidgetRef ref, String lang) {
    final selectedDate = ref.watch(selectedDateProvider);
    final historyAsync = ref.watch(historyProvider(selectedDate));

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
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => const Center(
        child: Text(
          'Failed to load history',
          style: TextStyle(color: AppColors.danger),
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
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? (imageUrl.startsWith('/') || imageUrl.startsWith('file://')
                          ? Image.file(
                              File(imageUrl.replaceFirst('file://', '')),
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => const _FoodPlaceholder(),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => const _FoodPlaceholder(),
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: AppColors.surfaceMuted,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ))
                      // No image → barcode icon (indicates barcode-scanned product)
                      : Container(
                          color: AppColors.surfaceMuted,
                          child: const Center(
                            child: Icon(LucideIcons.barcode, size: 30, color: AppColors.inactive),
                          ),
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
      if (logDate == today) return Translations.t(lang, 'today');
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
