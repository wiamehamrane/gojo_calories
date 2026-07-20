import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../domain/models/progress_photo.dart';

/// Progress journal tokens — theme-aware (follow [AppColors] light/dark).
Color get kPaper => AppColors.background;
Color get kSurface => AppColors.surface;
Color get kInk => AppColors.textPrimary;
Color get kInkSoft => AppColors.textSecondary;
Color get kMuted => AppColors.inactive;
Color get kHair => AppColors.border;
Color get kAccent => AppColors.primaryDark;
Color get kAccentBright => AppColors.primary;
Color get kAccentSoft => AppColors.primaryLight;
const Color kDanger = AppColors.danger;

/// Titles — system font, same weights as the rest of the app.
TextStyle display({
  double size = 16,
  FontWeight weight = FontWeight.w700,
  Color? color,
  double? height,
  double? spacing,
  FontStyle? style,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color ?? kInk,
    height: height,
    letterSpacing: spacing,
    fontStyle: style,
  );
}

/// Body / UI labels.
TextStyle body({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color? color,
  double? height,
  double? spacing,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color ?? kInkSoft,
    height: height,
    letterSpacing: spacing,
  );
}

/// Back-compat alias used across progress screens.
TextStyle serif({
  double size = 16,
  FontWeight weight = FontWeight.w700,
  Color? color,
  double? height,
  double? spacing,
  FontStyle? style,
}) =>
    display(
      size: size,
      weight: weight,
      color: color,
      height: height,
      spacing: spacing,
      style: style,
    );

class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: body(size: 13, weight: FontWeight.w500, color: color ?? kMuted),
    );
  }
}

/// White card matching soft profile-photo sheet cards.
class EditorialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  const EditorialCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: kHair),
        boxShadow: AppShadows.cardShadow,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

class ProgressPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final BorderRadius? borderRadius;

  const ProgressPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.borderRadius,
  });

  @override
  State<ProgressPressable> createState() => _ProgressPressableState();
}

class _ProgressPressableState extends State<ProgressPressable> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled
          ? (_) {
              _setPressed(false);
              if (widget.haptic && widget.onTap != null) {
                HapticFeedback.selectionClick();
              }
              widget.onTap?.call();
            }
          : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class AnimatedProgressRing extends StatelessWidget {
  final int count;
  final int total;
  final double size;
  final double strokeWidth;

  const AnimatedProgressRing({
    super.key,
    required this.count,
    required this.total,
    this.size = 56,
    this.strokeWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    final target = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: target),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  backgroundColor: AppColors.ringTrack,
                  valueColor: AlwaysStoppedAnimation(kAccentBright),
                  strokeCap: StrokeCap.round,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: Text(
                  '$count/$total',
                  key: ValueKey(count),
                  style: display(
                    size: size * 0.24,
                    weight: FontWeight.w700,
                    color: kAccent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SoftPulse extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const SoftPulse({
    super.key,
    required this.child,
    this.enabled = true,
    this.minScale = 1.0,
    this.maxScale = 1.015,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<SoftPulse> createState() => _SoftPulseState();
}

class _SoftPulseState extends State<SoftPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.enabled) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SoftPulse old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.enabled && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..animateTo(0, duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}

class SoftEntrance extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double beginY;

  const SoftEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.beginY = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .slideY(
          begin: beginY,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

class PoseSilhouettePainter extends CustomPainter {
  final BodyPose pose;
  final Color? color;

  PoseSilhouettePainter(this.pose, {this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = color ?? kAccent;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = c.withValues(alpha: 0.14);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = c.withValues(alpha: 0.5);

    final cx = size.width / 2;
    final h = size.height;
    final unit = h / 8;

    final headR = unit * 0.55;
    final headCenter = Offset(cx, unit * 0.9);
    canvas.drawCircle(headCenter, headR, paint);
    canvas.drawCircle(headCenter, headR, stroke);

    final bodyTop = headCenter.dy + headR;
    final path = Path();

    switch (pose) {
      case BodyPose.front:
      case BodyPose.back:
        final shoulder = unit * 1.15;
        final hip = unit * 0.85;
        path.moveTo(cx - shoulder, bodyTop + unit * 0.2);
        path.lineTo(cx + shoulder, bodyTop + unit * 0.2);
        path.lineTo(cx + hip, bodyTop + unit * 3.4);
        path.lineTo(cx - hip, bodyTop + unit * 3.4);
        path.close();
        _leg(canvas, cx - hip * 0.5, bodyTop + unit * 3.4, unit, paint, stroke);
        _leg(canvas, cx + hip * 0.5, bodyTop + unit * 3.4, unit, paint, stroke);
        _arm(canvas, cx - shoulder, bodyTop + unit * 0.3, -1, unit, paint, stroke);
        _arm(canvas, cx + shoulder, bodyTop + unit * 0.3, 1, unit, paint, stroke);
        break;
      case BodyPose.left:
      case BodyPose.right:
        final dir = pose == BodyPose.left ? -1.0 : 1.0;
        final w = unit * 0.7;
        path.moveTo(cx - w, bodyTop + unit * 0.2);
        path.lineTo(cx + w, bodyTop + unit * 0.2);
        path.lineTo(cx + w * 0.9, bodyTop + unit * 3.4);
        path.lineTo(cx - w * 0.9, bodyTop + unit * 3.4);
        path.close();
        _leg(canvas, cx, bodyTop + unit * 3.4, unit, paint, stroke);
        _arm(canvas, cx + dir * w * 0.4, bodyTop + unit * 0.4, dir, unit, paint,
            stroke);
        break;
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
  }

  void _leg(
      Canvas c, double x, double top, double unit, Paint fill, Paint stroke) {
    final r = Rect.fromLTWH(x - unit * 0.28, top, unit * 0.56, unit * 3.0);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(unit * 0.28));
    c.drawRRect(rr, fill);
    c.drawRRect(rr, stroke);
  }

  void _arm(Canvas c, double x, double top, double dir, double unit, Paint fill,
      Paint stroke) {
    final r = Rect.fromLTWH(
        x - unit * 0.18 + dir * unit * 0.1, top, unit * 0.36, unit * 2.4);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(unit * 0.2));
    c.drawRRect(rr, fill);
    c.drawRRect(rr, stroke);
  }

  @override
  bool shouldRepaint(PoseSilhouettePainter old) =>
      old.pose != pose || old.color != color;
}
