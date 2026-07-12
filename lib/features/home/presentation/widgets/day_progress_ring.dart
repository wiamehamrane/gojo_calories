import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'donut_ring_painter.dart';
import 'dotted_circle_painter.dart';

class DayProgressRing extends StatelessWidget {
  final int dayOfMonth;
  final double progress;
  final bool isOverGoal;
  final bool isSelected;
  final Color dayColor;
  final bool hasData;

  const DayProgressRing({
    super.key,
    required this.dayOfMonth,
    required this.progress,
    required this.isOverGoal,
    required this.isSelected,
    required this.dayColor,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    const stroke = 3.0;

    if (!hasData) {
      if (isSelected) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryDark,
          ),
          alignment: Alignment.center,
          child: Text(
            '$dayOfMonth',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
      }

      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: DottedCirclePainter(
            color: AppColors.inactive.withValues(alpha: 0.6),
            strokeWidth: 2.0,
            dashWidth: 4.0,
            dashSpace: 3.0,
          ),
          child: Center(
            child: Text(
              '$dayOfMonth',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    final ringProgress = isOverGoal ? 1.0 : progress.clamp(0.0, 1.0);
    final progressColor = isOverGoal
        ? const Color(0xFFE65100)
        : (isSelected ? AppColors.primaryDark : dayColor);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: DonutRingPainter(
              trackColor: AppColors.ringTrack,
              progressColor: progressColor,
              strokeWidth: stroke,
              progress: ringProgress,
            ),
          ),
          if (isSelected)
            Container(
              width: size - stroke * 2 - 4,
              height: size - stroke * 2 - 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark,
              ),
              alignment: Alignment.center,
              child: Text(
                '$dayOfMonth',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          else
            Text(
              '$dayOfMonth',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: progress > 0 ? AppColors.textPrimary : AppColors.inactive,
              ),
            ),
        ],
      ),
    );
  }
}
