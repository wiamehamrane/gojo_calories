import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';

/// First step after tapping "+ Share yours": pick new vs existing meal.
class ShareMealChooserScreen extends StatelessWidget {
  const ShareMealChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            size: 24,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: Text(
          'Share a meal',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                'How do you want to share?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              )
                  .animate()
                  .fadeIn(duration: 420.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.18, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 10),
              Text(
                'Share something you already logged, or create a new community meal from scratch.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 420.ms)
                  .slideY(begin: 0.12, end: 0, delay: 80.ms, duration: 420.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tileSize = ((constraints.maxWidth - 16) / 2).clamp(0.0, 168.0);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SquareOption(
                        size: tileSize,
                        icon: LucideIcons.history,
                        title: 'Existing meal',
                        subtitle: 'From your log',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push(RoutePaths.shareExistingMeal);
                        },
                      )
                          .animate()
                          .fadeIn(delay: 160.ms, duration: 480.ms)
                          .scale(
                            begin: const Offset(0.86, 0.86),
                            end: const Offset(1, 1),
                            delay: 160.ms,
                            duration: 520.ms,
                            curve: Curves.easeOutBack,
                          )
                          .slideX(begin: -0.12, end: 0, delay: 160.ms, duration: 480.ms, curve: Curves.easeOutCubic),
                      const SizedBox(width: 16),
                      _SquareOption(
                        size: tileSize,
                        icon: LucideIcons.plus,
                        title: 'New meal',
                        subtitle: 'From scratch',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push(RoutePaths.shareMeal);
                        },
                      )
                          .animate()
                          .fadeIn(delay: 260.ms, duration: 480.ms)
                          .scale(
                            begin: const Offset(0.86, 0.86),
                            end: const Offset(1, 1),
                            delay: 260.ms,
                            duration: 520.ms,
                            curve: Curves.easeOutBack,
                          )
                          .slideX(begin: 0.12, end: 0, delay: 260.ms, duration: 480.ms, curve: Curves.easeOutCubic),
                    ],
                  );
                },
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareOption extends StatefulWidget {
  final double size;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SquareOption({
    required this.size,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_SquareOption> createState() => _SquareOptionState();
}

class _SquareOptionState extends State<_SquareOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: widget.size,
          height: widget.size,
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _pressed ? AppColors.primary : AppColors.border,
              width: _pressed ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.04 : 0.07),
                blurRadius: _pressed ? 8 : 18,
                offset: Offset(0, _pressed ? 2 : 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
