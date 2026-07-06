import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/translations.dart';
import '../widgets/donut_ring_painter.dart';

class MacroTileInner extends StatefulWidget {
  final String macroName;
  final String lang;
  final int total;
  final int consumed;
  final Color macroColor;
  final IconData macroIcon;

  const MacroTileInner({
    super.key,
    required this.macroName,
    required this.lang,
    required this.total,
    required this.consumed,
    required this.macroColor,
    required this.macroIcon,
  });

  @override
  State<MacroTileInner> createState() => _MacroTileInnerState();
}

class _MacroTileInnerState extends State<MacroTileInner>
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
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
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
    final rawLeft = widget.total - widget.consumed;
    final isOverGoal = !_showConsumed && rawLeft < 0;
    final surplus = widget.consumed - widget.total;

    final int displayValue = _showConsumed
        ? widget.consumed
        : (isOverGoal ? surplus : (rawLeft < 0 ? 0 : rawLeft));

    final String verb = _showConsumed
        ? Translations.t(widget.lang, 'eaten')
        : (isOverGoal
            ? Translations.t(widget.lang, 'over_goal')
            : Translations.t(widget.lang, 'left'));

    final Color verbColor =
        isOverGoal ? _overGoalColor : AppColors.textSecondary;

    final double progress = widget.total > 0
        ? (widget.consumed / widget.total).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) => FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(scale: _scaleAnim, child: child),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${displayValue}g',
                    style: AppTextStyles.macroValue.copyWith(
                      color: isOverGoal ? _overGoalColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.macroName} ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: verb,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: verbColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 4,
                      color: AppColors.ringTrack,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(color: widget.macroColor),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(44, 44),
                        painter: DonutRingPainter(
                          trackColor: AppColors.ringTrack,
                          progressColor: widget.macroColor,
                          strokeWidth: 5.0,
                          progress: progress,
                        ),
                      ),
                      Center(
                        child: Icon(
                          widget.macroIcon,
                          size: 16,
                          color: widget.macroColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
