import 'dart:math';
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
import 'package:intl/intl.dart';
import '../widgets/swipable_stat_card.dart';
import '../widgets/calorie_ring_inner.dart';
import '../widgets/macro_tile_inner.dart';
import '../widgets/weekly_calendar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    final lang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.white, // fallback
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE5E5E8), // darker top
              AppColors.background, // lighter bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _buildHeader(context, ref),
              const SizedBox(height: 8), // closer to title
              const WeeklyCalendar(),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: _buildCalorieRingCard(context, stats, lang),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: _buildMacroTilesRow(context, stats, lang),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Text(
                  Translations.t(lang, 'recently_uploaded'),
                  style: AppTextStyles.sectionHeader.copyWith(color: Colors.black),
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentMeals(context, ref, lang),
              const SizedBox(height: 100), // padding for FAB and Nav
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
      orElse: () => "0",
    );
    return Container(
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
                "GojoCalories",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black, // Pure black
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  streakValue,
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildCalorieRingCard(BuildContext context, stats, String lang) {
    return SwipableStatCard(
      title: 'Calories',
      themeColor: AppColors.primaryMid,
      primaryView: CalorieRingInner(stats: stats, lang: lang),
    );
  }

  Widget _buildMacroTilesRow(BuildContext context, stats, String lang) {
    return Row(
      children: [
        Expanded(
          child: SwipableStatCard(
            title: 'Protein',
            themeColor: AppColors.protein,
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
    );
  }

  Widget _buildRecentMeals(BuildContext context, WidgetRef ref, String lang) {
    final selectedDate = ref.watch(selectedDateProvider);
    final historyAsync = ref.watch(historyProvider(selectedDate));

    return historyAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 10),
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
          );
        }
        return Column(
          children: List.generate(
            logs.length,
            (i) => _AnimatedMealCard(log: logs[i], index: i, lang: lang),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
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
      duration: Duration(milliseconds: 350 + widget.index * 60),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
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
    
    // Choose name based on language
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Food thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _FoodPlaceholder(),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.surfaceMuted,
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const _FoodPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealName,
                        style: AppTextStyles.bodyBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.flame,
                            size: 14,
                            color: AppColors.fire,
                          ),
                          Text(
                            ' $calories kcal',
                            style: AppTextStyles.bodyRegular,
                          ),
                        ],
                      ),
                      if (protein.isNotEmpty ||
                          carbs.isNotEmpty ||
                          fat.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (protein.isNotEmpty)
                              _MacroChip(
                                label: '${protein}g P',
                                color: AppColors.protein,
                              ),
                            if (carbs.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _MacroChip(
                                label: '${carbs}g C',
                                color: AppColors.carbs,
                              ),
                            ],
                            if (fat.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _MacroChip(
                                label: '${fat}g F',
                                color: AppColors.fats,
                              ),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inactive,
                  ),
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

      if (logDate == today) {
        return Translations.t(lang, 'today');
      } else if (logDate == yesterday) {
        return 'Yesterday'; // Or add to translations
      } else {
        return DateFormat('MMM d').format(date);
      }
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
        child: Icon(LucideIcons.utensils, size: 26, color: AppColors.inactive),
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

  // The old _MacroTile is removed since we externalized it.

class DonutRingPainter extends CustomPainter {
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final double progress;

  DonutRingPainter({
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DonutRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// The old _WeeklyCalendar is removed since we externalized it.
