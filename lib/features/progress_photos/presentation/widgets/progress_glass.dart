import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/progress_photo.dart';

/// Light, editorial palette for the body-journal experience. Warm off-white
/// paper, near-black ink, hairline rules, generous whitespace and a single
/// restrained accent — an Apple-Health-premium / magazine feel.
const Color kPaper = Color(0xFFFBFAF7); // page background
const Color kSurface = Color(0xFFFFFFFF); // cards
const Color kInk = Color(0xFF1C1B19); // primary text
const Color kInkSoft = Color(0xFF6C6A64); // secondary text
const Color kMuted = Color(0xFF9C9A93); // captions / placeholders
const Color kHair = Color(0xFFEAE7E0); // hairline borders + dividers
const Color kAccent = Color(0xFF0B7A6E); // deep teal accent
const Color kAccentSoft = Color(0xFFEAF3F0); // accent tint background
const Color kDanger = Color(0xFFB4463A); // muted brick for destructive

/// Editorial serif (Fraunces) for display headings and figures.
TextStyle serif({
  double size = 16,
  FontWeight weight = FontWeight.w500,
  Color color = kInk,
  double? height,
  double? spacing,
  FontStyle? style,
}) {
  return GoogleFonts.fraunces(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
    fontStyle: style,
  );
}

/// A small tracked uppercase eyebrow label, common in editorial layouts.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = kMuted});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: color,
      ),
    );
  }
}

/// White surface with a hairline border and a very soft lift.
class EditorialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  const EditorialCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 18,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// Stylized standing-body silhouette that reorients per pose so the user knows
/// which way to face. Not anatomically precise — a clear guide only.
class PoseSilhouettePainter extends CustomPainter {
  final BodyPose pose;
  final Color color;

  PoseSilhouettePainter(this.pose, {this.color = kAccent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.14);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.5);

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
        _arm(canvas, cx + dir * w * 0.4, bodyTop + unit * 0.4, dir, unit, paint, stroke);
        break;
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
  }

  void _leg(Canvas c, double x, double top, double unit, Paint fill, Paint stroke) {
    final r = Rect.fromLTWH(x - unit * 0.28, top, unit * 0.56, unit * 3.0);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(unit * 0.28));
    c.drawRRect(rr, fill);
    c.drawRRect(rr, stroke);
  }

  void _arm(Canvas c, double x, double top, double dir, double unit, Paint fill, Paint stroke) {
    final r = Rect.fromLTWH(x - unit * 0.18 + dir * unit * 0.1, top, unit * 0.36, unit * 2.4);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(unit * 0.2));
    c.drawRRect(rr, fill);
    c.drawRRect(rr, stroke);
  }

  @override
  bool shouldRepaint(PoseSilhouettePainter old) =>
      old.pose != pose || old.color != color;
}
