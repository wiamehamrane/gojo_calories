import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/donut_ring_painter.dart';

class MacroTileInner extends StatefulWidget {
  final String macroName;
  final int total;
  final int consumed;
  final Color macroColor;
  final IconData macroIcon;

  const MacroTileInner({
    super.key,
    required this.macroName,
    required this.total,
    required this.consumed,
    required this.macroColor,
    required this.macroIcon,
  });

  @override
  State<MacroTileInner> createState() => _MacroTileInnerState();
}

class _MacroTileInnerState extends State<MacroTileInner> {
  bool _showConsumed = false;

  @override
  Widget build(BuildContext context) {
    int left = widget.total - widget.consumed;
    left = left < 0 ? 0 : left;
    
    final int displayValue = _showConsumed ? widget.consumed : left;
    final String verb = _showConsumed ? "cons." : "left";

    final double progress = widget.total > 0
        ? (widget.consumed / widget.total).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showConsumed = !_showConsumed),
      child: Container(
        color: Colors.transparent, // capture gesture
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                "${displayValue}g",
                key: ValueKey<int>(displayValue),
                style: AppTextStyles.macroValue,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: RichText(
                key: ValueKey<bool>(_showConsumed),
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${widget.macroName} ",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: verb,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(56, 56),
                      painter: DonutRingPainter(
                        trackColor: AppColors.ringTrack,
                        progressColor: widget.macroColor,
                        strokeWidth: 6.0,
                        progress: progress,
                      ),
                    ),
                    Center(child: Icon(widget.macroIcon, size: 20, color: widget.macroColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
