import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/daily_stats.dart';
import '../../../../core/localization/translations.dart';
import '../screens/home_screen.dart'; // For DonutRingPainter

class CalorieRingInner extends StatefulWidget {
  final DailyStats stats;
  final String lang;

  const CalorieRingInner({super.key, required this.stats, required this.lang});

  @override
  State<CalorieRingInner> createState() => _CalorieRingInnerState();
}

class _CalorieRingInnerState extends State<CalorieRingInner> {
  bool _showConsumed = false;

  @override
  Widget build(BuildContext context) {
    final int caloriesLeft = widget.stats.calorieBudget > 0 ? widget.stats.calorieBudget - widget.stats.caloriesConsumed : 0;
    final int displayValue = _showConsumed ? widget.stats.caloriesConsumed : caloriesLeft;
    
    final double progress = widget.stats.calorieBudget > 0
        ? (widget.stats.caloriesConsumed / widget.stats.calorieBudget).clamp(0.0, 1.0)
        : 0.0;

    String verbLabel = _showConsumed
        ? Translations.t(widget.lang, 'consumed')
        : Translations.t(widget.lang, 'calories_left').split(' ').skip(1).join(' '); // usually "left"
    
    // Quick fallback
    if (verbLabel.isEmpty) verbLabel = _showConsumed ? "consumed" : "left";

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showConsumed = !_showConsumed),
      child: Container(
        color: Colors.transparent, // For gesture
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: Text(
                    displayValue.toString(),
                    key: ValueKey<int>(displayValue),
                    style: AppTextStyles.heroNumber,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: RichText(
                    key: ValueKey<bool>(_showConsumed),
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Calories ",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: verbLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
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
                    child: SvgPicture.asset(
                      'assets/icons/flame_gradient.svg',
                      width: 24,
                      height: 24,
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
