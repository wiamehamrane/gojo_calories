import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/history_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    final lang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref),
              const SizedBox(height: 16),
              const _WeeklyCalendar(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: _buildCalorieRingCard(context, stats, lang),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: _buildMacroTilesRow(context, stats, lang),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Text(Translations.t(lang, 'recently_uploaded'), style: AppTextStyles.sectionHeader),
              ),
              const SizedBox(height: 12),
              _buildRecentMeals(context, ref, lang),
              const SizedBox(height: 100), // padding for FAB and Nav
            ],
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
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🥑', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 6),
              const Text(
                "GojoCalories",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0,1))],
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/icons/flame_gradient.svg', width: 20, height: 20),
                const SizedBox(width: 6),
                Text(
                  streakValue,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCalorieRingCard(BuildContext context, stats, String lang) {
    final int caloriesLeft = stats.calorieBudget - stats.caloriesConsumed;
    final double progress = stats.calorieBudget > 0 ? (stats.caloriesConsumed / stats.calorieBudget).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: caloriesLeft > 0 ? caloriesLeft : 0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, val, child) => Text(val.toString(), style: AppTextStyles.heroNumber),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: "${Translations.t(lang, 'calories_left').split(' ').first} ", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
                    TextSpan(text: Translations.t(lang, 'calories_left').split(' ').skip(1).join(' '), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(96, 96),
                  painter: DonutRingPainter(
                    trackColor: AppColors.ringTrack,
                    progressColor: AppColors.primaryMid,
                    strokeWidth: 10.0,
                    progress: progress,
                  ),
                ),
                Center(
                  child: SvgPicture.asset('assets/icons/flame_gradient.svg', width: 24, height: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroTilesRow(BuildContext context, stats, String lang) {
    return Row(
      children: [
        Expanded(child: _MacroTile(
          macroName: Translations.t(lang, 'macro_protein'),
          total: stats.proteinTarget,
          consumed: stats.proteinConsumed,
          macroColor: AppColors.protein,
          macroIcon: LucideIcons.beef,
        )),
        const SizedBox(width: AppSpacing.macroTileGap),
        Expanded(child: _MacroTile(
          macroName: Translations.t(lang, 'macro_carbs'),
          total: stats.carbsTarget,
          consumed: stats.carbsConsumed,
          macroColor: AppColors.carbs,
          macroIcon: LucideIcons.wheat,
        )),
        const SizedBox(width: AppSpacing.macroTileGap),
        Expanded(child: _MacroTile(
          macroName: Translations.t(lang, 'macro_fats'),
          total: stats.fatTarget,
          consumed: stats.fatConsumed,
          macroColor: AppColors.fats,
          macroIcon: LucideIcons.droplets,
        )),
      ],
    );
  }

  Widget _buildRecentMeals(BuildContext context, WidgetRef ref, String lang) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Icon(LucideIcons.utensilsCrossed, size: 48, color: AppColors.inactive),
                const SizedBox(height: 12),
                Text(Translations.t(lang, 'no_food_logged'), style: const TextStyle(fontSize: 15, color: AppColors.inactive)),
              ],
            ),
          );
        }

        return Column(
          children: logs.map<Widget>((log) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.thumb),
                    child: Container(
                      width: 64, height: 64,
                      color: AppColors.surfaceMuted,
                      child: const Icon(LucideIcons.image, size: 28, color: AppColors.inactive),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['meal_name'] ?? 'Unknown Meal', style: AppTextStyles.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.flame, size: 14, color: AppColors.fire),
                            Text(" ${log['calories']} calories", style: AppTextStyles.bodyRegular),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(Translations.t(lang, 'today'), style: const TextStyle(fontSize: 12, color: AppColors.inactive)),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => const Center(child: Text('Failed to load history', style: TextStyle(color: AppColors.danger))),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String macroName;
  final int total;
  final int consumed;
  final Color macroColor;
  final IconData macroIcon;

  const _MacroTile({
    required this.macroName, required this.total, required this.consumed, required this.macroColor, required this.macroIcon,
  });

  @override
  Widget build(BuildContext context) {
    int left = total - consumed;
    left = left < 0 ? 0 : left;
    final double progress = total > 0 ? (consumed / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${left}g", style: AppTextStyles.macroValue),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "$macroName ", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const TextSpan(text: "left", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 56, height: 56,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(56, 56),
                    painter: DonutRingPainter(
                      trackColor: AppColors.ringTrack,
                      progressColor: macroColor,
                      strokeWidth: 6.0,
                      progress: progress,
                    ),
                  ),
                  Center(child: Icon(macroIcon, size: 20, color: macroColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutRingPainter extends CustomPainter {
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final double progress;

  DonutRingPainter({
    required this.trackColor, required this.progressColor, required this.strokeWidth, required this.progress,
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

class _WeeklyCalendar extends StatefulWidget {
  const _WeeklyCalendar();
  @override
  State<_WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<_WeeklyCalendar> {
  late int _selectedDayOffset;
  
  @override
  void initState() {
    super.initState();
    _selectedDayOffset = DateTime.now().weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    return SizedBox(
      height: 72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final isSelected = i == _selectedDayOffset;
          final isFuture = i > (now.weekday % 7);
          final dayDate = now.day - (now.weekday % 7) + i;
          
          return GestureDetector(
            onTap: isFuture ? null : () => setState(() => _selectedDayOffset = i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  days[i],
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inactive),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primaryDark : (isFuture ? const Color(0xFFDDDDDD) : const Color(0xFFCECECE)),
                      width: isSelected ? 2 : 1.5,
                    ),
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      "$dayDate",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
