import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class HomeDayShimmer extends StatefulWidget {
  const HomeDayShimmer({super.key});

  @override
  State<HomeDayShimmer> createState() => _HomeDayShimmerState();
}

class _HomeDayShimmerState extends State<HomeDayShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _shimmerColor =>
      Color.lerp(
        AppColors.surfaceMuted,
        AppColors.surface,
        _animation.value,
      ) ??
      AppColors.surfaceMuted;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final color = _shimmerColor;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: _ShimmerBox(
                color: color,
                height: 160,
                borderRadius: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.cardGap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ShimmerBox(color: color, height: 160, borderRadius: 20),
                  ),
                  const SizedBox(width: AppSpacing.macroTileGap),
                  Expanded(
                    child: _ShimmerBox(color: color, height: 160, borderRadius: 20),
                  ),
                  const SizedBox(width: AppSpacing.macroTileGap),
                  Expanded(
                    child: _ShimmerBox(color: color, height: 160, borderRadius: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: _ShimmerBox(color: color, height: 22, width: 160, borderRadius: 8),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                children: [
                  _mealRow(color),
                  const SizedBox(height: 10),
                  _mealRow(color),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: _ShimmerBox(color: color, height: 22, width: 120, borderRadius: 8),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                children: [
                  _workoutRow(color),
                  const SizedBox(height: 10),
                  _workoutRow(color),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _mealRow(Color color) {
    return Container(
      height: 72,
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
          _ShimmerBox(color: color, width: 72, height: 72, borderRadius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(color: color, height: 14, width: 140, borderRadius: 6),
                const SizedBox(height: 8),
                _ShimmerBox(color: color, height: 12, width: 90, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ShimmerBox(color: color, height: 16, width: 40, borderRadius: 6),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _workoutRow(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          _ShimmerBox(color: color, width: 44, height: 44, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(color: color, height: 14, width: 120, borderRadius: 6),
                const SizedBox(height: 6),
                _ShimmerBox(color: color, height: 12, width: 80, borderRadius: 6),
              ],
            ),
          ),
          _ShimmerBox(color: color, height: 16, width: 36, borderRadius: 6),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final Color color;
  final double? width;
  final double? height;
  final double borderRadius;

  const _ShimmerBox({
    required this.color,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
