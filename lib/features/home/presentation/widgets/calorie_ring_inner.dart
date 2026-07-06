import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/translations.dart';
import '../../../stats/data/models/daily_stats.dart';
import '../widgets/donut_ring_painter.dart';

class CalorieRingInner extends StatefulWidget {
  final DailyStats stats;
  final String lang;

  const CalorieRingInner({super.key, required this.stats, required this.lang});

  @override
  State<CalorieRingInner> createState() => _CalorieRingInnerState();
}

class _CalorieRingInnerState extends State<CalorieRingInner>
    with SingleTickerProviderStateMixin {
  bool _showConsumed = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  static const _overGoalColor = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.value = 1.0;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    _animController.reverse().then((_) {
      setState(() => _showConsumed = !_showConsumed);
      _animController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final rawLeft = widget.stats.calorieBudget - widget.stats.caloriesConsumed;
    final isOverGoal = !_showConsumed && rawLeft < 0;
    final surplus = widget.stats.caloriesConsumed - widget.stats.calorieBudget;

    final int displayValue = _showConsumed
        ? widget.stats.caloriesConsumed
        : (isOverGoal ? surplus : (rawLeft < 0 ? 0 : rawLeft));

    final double progress = widget.stats.calorieBudget > 0
        ? (widget.stats.caloriesConsumed / widget.stats.calorieBudget)
            .clamp(0.0, 1.0)
        : 0.0;

    final String verbLabel = _showConsumed
        ? Translations.t(lang, 'consumed')
        : (isOverGoal
            ? Translations.t(lang, 'over_goal')
            : Translations.t(lang, 'left'));

    final Color verbColor =
        isOverGoal ? _overGoalColor : AppColors.textPrimary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) => FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: child,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayValue.toString(),
                    style: AppTextStyles.heroNumber.copyWith(
                      color: isOverGoal ? _overGoalColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Calories ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: verbLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: verbColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 100,
                      height: 5,
                      color: AppColors.ringTrack,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryMid,
                                  AppColors.primary,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 86,
              height: 86,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(86, 86),
                    painter: DonutRingPainter(
                      trackColor: AppColors.ringTrack,
                      progressColor: AppColors.primaryMid,
                      strokeWidth: 9.0,
                      progress: progress,
                    ),
                  ),
                  Center(
                    child: SvgPicture.asset(
                      'assets/icons/flame_gradient.svg',
                      width: 26,
                      height: 26,
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
